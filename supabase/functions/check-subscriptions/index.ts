// supabase/functions/check-subscriptions/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    const now = new Date();
    const day3 = new Date(now.getTime() + 3 * 86400000).toISOString();
    const day5 = new Date(now.getTime() + 5 * 86400000).toISOString();

    // 1. MARQUE LES EXPIRÉS
    console.log('🔍 Vérification des abonnements expirés...');
    const { data: expired, error: expiredError } = await supabase.rpc('check_expired_subscriptions');
    
    if (expiredError) {
      console.error('❌ Erreur check_expired_subscriptions:', expiredError);
      throw expiredError;
    }
    console.log(`✅ ${expired?.length || 0} abonnements marqués comme expirés`);

    // 2. RÉCUPÈRE CEUX QUI EXPIRENT DANS 3-5 JOURS
    console.log(`🔍 Recherche des abonnements expirant entre ${day3.slice(0,10)} et ${day5.slice(0,10)}...`);
    
    const { data: expiringTrial, error: trialError } = await supabase
      .from('parent_subscriptions')
      .select(`
        id,
        parent_id,
        school_id,
        status,
        trial_ends_at,
        current_period_end,
        app_users!inner(first_name, last_name, phone),
        schools!inner(name, country)
      `)
      .eq('status', 'trial')
      .gte('trial_ends_at', day3)
      .lte('trial_ends_at', day5);

    if (trialError) {
      console.error('❌ Erreur requête trial:', trialError);
      throw trialError;
    }

    const { data: expiringActive, error: activeError } = await supabase
      .from('parent_subscriptions')
      .select(`
        id,
        parent_id,
        school_id,
        status,
        trial_ends_at,
        current_period_end,
        app_users!inner(first_name, last_name, phone),
        schools!inner(name, country)
      `)
      .eq('status', 'active')
      .gte('current_period_end', day3)
      .lte('current_period_end', day5);

    if (activeError) {
      console.error('❌ Erreur requête active:', activeError);
      throw activeError;
    }

    const expiringSoon = [...(expiringTrial || []), ...(expiringActive || [])];
    console.log(`✅ ${expiringSoon.length} abonnements expirent bientôt`);

    // 3. CRÉE LES RAPPELS
    let remindersCreated = 0;
    
    if (expiringSoon.length > 0) {
      const today = now.toISOString().slice(0, 10);
      
      for (const sub of expiringSoon) {
        const parent = Array.isArray(sub.app_users) ? sub.app_users[0] : sub.app_users;
        const school = Array.isArray(sub.schools) ? sub.schools[0] : sub.schools;

        // Vérifie si rappel déjà envoyé aujourd'hui
        const { data: existingReminder } = await supabase
          .from('subscription_reminders')
          .select('id')
          .eq('parent_id', sub.parent_id)
          .gte('created_at', today)
          .limit(1);

        if (existingReminder && existingReminder.length > 0) {
          console.log(`⏭ Rappel déjà envoyé aujourd'hui à ${parent?.first_name || sub.parent_id}`);
          continue;
        }

        // Calcule les jours restants
        const endDate = sub.status === 'trial' ? sub.trial_ends_at : sub.current_period_end;
        const daysLeft = Math.ceil((new Date(endDate).getTime() - now.getTime()) / 86400000);

        const parentName = parent?.first_name || 'votre enfant';

        // Insère le rappel
        const { error: reminderError } = await supabase
          .from('subscription_reminders')
          .insert({
            parent_id: sub.parent_id,
            school_id: sub.school_id,
            subscription_id: sub.id,
            days_remaining: daysLeft,
            status: 'pending',
            message: `Votre abonnement expire dans ${daysLeft} jour(s). Renouvelez pour continuer à suivre ${parentName}.`,
            created_at: now.toISOString(),
          });

        if (reminderError) {
          console.error('❌ Erreur insertion reminder:', reminderError);
        } else {
          remindersCreated++;
          console.log(`✅ Rappel créé pour ${parentName} (${daysLeft}j restants)`);
        }
      }
    }

    // 4. RÉPONSE
    return new Response(
      JSON.stringify({
        success: true,
        expired_count: expired?.length || 0,
        reminders_created: remindersCreated,
        checked_at: now.toISOString(),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    // ✅ CORRIGÉ : Type guard pour error unknown
    let errorMessage = 'Erreur inconnue';
    
    if (error instanceof Error) {
      errorMessage = error.message;
    } else if (typeof error === 'string') {
      errorMessage = error;
    } else if (error && typeof error === 'object' && 'message' in error) {
      errorMessage = String((error as Record<string, unknown>).message);
    }

    console.error('❌ Erreur globale:', errorMessage);
    
    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});