// supabase/functions/bulk-import/handlers/teachers.ts
import { cleanString, normalizePhone } from '../utils.ts'

export async function handleTeachers(
  supabaseAdmin: any,
  row: any,
  schoolId: string,
  schoolCode: string,
  results: any
): Promise<void> {
  const phone = row.telephone ? normalizePhone(row.telephone) : null
  const subjects = cleanString(row.matiere, true)
    .split(/[;,]/)
    .map((s: string) => s.trim())
    .filter((s: string) => s)

  const { data: existingTeacher } = await supabaseAdmin
    .from('users')
    .select('id')
    .eq('email', cleanString(row.email, true).toLowerCase())
    .eq('role', 'teacher')
    .maybeSingle()

  if (existingTeacher) {
    await supabaseAdmin.from('users').update({ 
      first_name: cleanString(row.prenom, true), 
      last_name: cleanString(row.nom, true), 
      phone: phone, 
      updated_at: new Date().toISOString() 
    }).eq('id', existingTeacher.id)

    await supabaseAdmin.from('teacher_profiles').update({ 
      specialization: subjects.join(', ') 
    }).eq('user_id', existingTeacher.id)

    results.updated++
  } else {
    const { data: rpcResult, error: rpcError } = await supabaseAdmin.rpc('create_teacher_user', {
      p_email: cleanString(row.email, true).toLowerCase(),
      p_first_name: cleanString(row.prenom, true),
      p_last_name: cleanString(row.nom, true),
      p_phone: phone,
      p_school_api_key: schoolCode,
      p_school_id: schoolId,
      p_password: row.mot_de_passe || 'EduConnect2024!',
      p_subjects: subjects
    })

    if (rpcError || !rpcResult?.success) {
      throw new Error(`Création enseignant: ${rpcError?.message || rpcResult?.error}`)
    }
    results.created++
  }
}
