// supabase/functions/bulk-create-auth-users/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const BATCH_SIZE = 50;

serve(async (req) => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, { headers, status: 204 });
  }

  try {
    const { schoolCode, roleFilter = ['teacher', 'admin', 'parent'], customPassword = null, dryRun = false } = await req.json();

    if (!schoolCode) {
      throw new Error('schoolCode requis');
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    
    console.log('🔍 ENV CHECK:', {
      url_exists: !!supabaseUrl,
      key_exists: !!serviceRoleKey,
      key_length: serviceRoleKey?.length || 0
    });

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('Variables d\'environnement manquantes');
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false }
    });

    const { data: school, error: schoolError } = await supabaseAdmin
      .from('schools')
      .select('id, name')
      .eq('school_code', schoolCode)
      .single();

    if (schoolError || !school) {
      throw new Error(`École non trouvée: ${schoolError?.message || schoolCode}`);
    }

    const { data: users, error: usersError } = await supabaseAdmin
      .from('app_users')
      .select('id, email, phone, first_name, last_name, role, school_id')
      .eq('school_id', school.id)
      .in('role', roleFilter)
      .is('auth_id', null)
      .eq('is_active', true);

    if (usersError) throw new Error(`Erreur récupération users: ${usersError.message}`);

    if (!users || users.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: 'Aucun utilisateur à créer',
        school: school.name,
        processed: 0,
        created: 0,
        errors: 0,
        details: []
      }), { headers });
    }

    const results = {
      total: users.length,
      created: 0,
      skipped: 0,
      errors: 0,
      details: [] as any[],
      credentials: [] as any[]
    };

    for (let i = 0; i < users.length; i += BATCH_SIZE) {
      const batch = users.slice(i, i + BATCH_SIZE);
      
      await Promise.all(batch.map(async (user) => {
        try {
          const password = customPassword || generatePassword(user);
          const email = user.email || generateParentEmail(user);
          
          if (!email) {
            results.skipped++;
            results.details.push({
              id: user.id,
              name: `${user.first_name} ${user.last_name}`,
              role: user.role,
              status: 'skipped',
              reason: 'Pas d\'email ni de téléphone'
            });
            return;
          }

          if (dryRun) {
            results.details.push({
              id: user.id,
              email: email,
              name: `${user.first_name} ${user.last_name}`,
              role: user.role,
              status: 'dry_run',
              password: password
            });
            return;
          }

          const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
            email: email,
            password: password,
            email_confirm: true,
            user_metadata: {
              first_name: user.first_name,
              last_name: user.last_name,
              role: user.role,
              school_id: school.id,
              app_user_id: user.id
            }
          });

          if (authError) {
            if (authError.message.includes('already exists') || authError.message.includes('duplicate')) {
              const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
              const found = existingUsers?.users?.find((u: any) => u.email === email);
              
              if (found) {
                await supabaseAdmin.from('app_users').update({ auth_id: found.id }).eq('id', user.id);
                results.created++;
                results.details.push({
                  id: user.id,
                  email: email,
                  name: `${user.first_name} ${user.last_name}`,
                  role: user.role,
                  status: 'linked_existing',
                  auth_id: found.id
                });
                return;
              }
            }
            throw authError;
          }

          await supabaseAdmin.from('app_users').update({ auth_id: authUser.user.id }).eq('id', user.id);

          results.created++;
          
          if (user.role !== 'parent') {
            results.credentials.push({
              email: email,
              password: password,
              role: user.role,
              name: `${user.first_name} ${user.last_name}`
            });
          }

          results.details.push({
            id: user.id,
            email: email,
            name: `${user.first_name} ${user.last_name}`,
            role: user.role,
            status: 'created',
            auth_id: authUser.user.id
          });

        } catch (err: any) {
          results.errors++;
          results.details.push({
            id: user.id,
            email: user.email,
            name: `${user.first_name} ${user.last_name}`,
            role: user.role,
            status: 'error',
            error: err.message
          });
        }
      }));
    }

    return new Response(JSON.stringify({
      success: true,
      school: school.name,
      school_id: school.id,
      summary: {
        total: results.total,
        created: results.created,
        skipped: results.skipped,
        errors: results.errors,
        dry_run: dryRun
      },
      credentials: dryRun ? null : results.credentials,
      details: results.details
    }, null, 2), { headers });

  } catch (error: any) {
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), { status: 400, headers });
  }
});

function generatePassword(user: any): string {
  const base = user.first_name.charAt(0).toUpperCase() + user.last_name.toLowerCase();
  const random = Math.random().toString(36).substring(2, 6);
  return `${base}@${random}`;
}

function generateParentEmail(user: any): string | null {
  if (!user.phone) return null;
  const cleanPhone = user.phone.replace(/[^0-9]/g, '');
  return `parent.${cleanPhone}@educonnect.app`;
}