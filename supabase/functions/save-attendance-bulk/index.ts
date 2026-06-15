// supabase/functions/save-attendance-bulk/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AttendanceRecord {
  student_id: string
  status: 'present' | 'absent' | 'late'
  notes?: string
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const authHeader = req.headers.get('authorization')!
    const token = authHeader.replace('Bearer ', '')

    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Non authentifié' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const body = await req.json()
    const { schedule_id, date, records } = body

    if (!schedule_id || !date || !records || !Array.isArray(records) || records.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Données invalides' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Vérification : l'enseignant est-il assigné à ce cours ?
    const { data: schedule, error: scheduleError } = await supabase
      .from('schedules')
      .select('id, teacher_id, class_id, school_id')
      .eq('id', schedule_id)
      .single()

    if (scheduleError || !schedule) {
      return new Response(
        JSON.stringify({ success: false, error: 'Cours introuvable' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { data: teacherCheck } = await supabase
      .from('teachers')
      .select('id')
      .eq('user_id', user.id)
      .eq('id', schedule.teacher_id)
      .maybeSingle()

    if (!teacherCheck) {
      return new Response(
        JSON.stringify({ success: false, error: 'Accès refusé' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Préparation du batch
    const now = new Date().toISOString()
    const attendanceRecords = records.map((r: AttendanceRecord) => ({
      student_id: r.student_id,
      schedule_id: schedule_id,
      date: date,
      status: r.status,
      school_id: schedule.school_id,
      class_id: schedule.class_id,
      notes: r.notes || null,
      created_at: now,
      updated_at: now,
    }))

    // UPSERT BATCH : INSERT ou UPDATE si conflit
    const { error } = await supabase
      .from('attendance')
      .upsert(attendanceRecords, {
        onConflict: 'student_id,schedule_id,date',
        ignoreDuplicates: false,
      })

    if (error) {
      console.error('Erreur upsert:', error)
      return new Response(
        JSON.stringify({ success: false, error: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `${records.length} présences enregistrées`,
        count: records.length,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    console.error('Erreur serveur:', err)
    return new Response(
      JSON.stringify({ success: false, error: 'Erreur serveur' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})