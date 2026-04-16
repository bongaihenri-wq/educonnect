// supabase/functions/bulk-import/handlers/schedules.ts
import { cleanString, dayToNumber, validateTime } from '../utils.ts'

export async function handleSchedules(
  supabaseAdmin: any,
  row: any,
  schoolId: string,
  schoolYear: string,
  results: any
): Promise<void> {
  const dayOfWeek = dayToNumber(cleanString(row.jour, true))
  const startTime = validateTime(cleanString(row.heure_debut, true))
  const endTime = validateTime(cleanString(row.heure_fin, true))

  if (startTime >= endTime) {
    throw new Error(`Heure fin (${endTime}) doit être après début (${startTime})`)
  }

  const { data: classe } = await supabaseAdmin
    .from('classes')
    .select('id, level_id')
    .eq('name', cleanString(row.classe, true))
    .eq('school_id', schoolId)
    .maybeSingle()

  if (!classe) throw new Error(`Classe non trouvée: ${row.classe}`)

  let subjectId: string
  const { data: existingSubject } = await supabaseAdmin
    .from('subjects')
    .select('id')
    .eq('name', cleanString(row.matiere, true))
    .eq('school_id', schoolId)
    .maybeSingle()

  if (existingSubject) {
    subjectId = existingSubject.id
  } else {
    const { data: newSubject, error } = await supabaseAdmin
      .from('subjects')
      .insert({ 
        name: cleanString(row.matiere, true), 
        school_id: schoolId, 
        level_id: classe.level_id 
      })
      .select('id')
      .single()
    if (error) throw error
    subjectId = newSubject!.id
  }

  const { data: teacher } = await supabaseAdmin
    .from('users')
    .select('id')
    .eq('email', cleanString(row.enseignant_email, true).toLowerCase())
    .eq('role', 'teacher')
    .maybeSingle()

  if (!teacher) throw new Error(`Enseignant non trouvé: ${row.enseignant_email}`)

  await supabaseAdmin.from('schedules')
    .delete()
    .eq('class_id', classe.id)
    .eq('day_of_week', dayOfWeek)
    .eq('start_time', startTime)

  const { error } = await supabaseAdmin.from('schedules').insert({
    class_id: classe.id,
    subject_id: subjectId,
    teacher_id: teacher.id,
    day_of_week: dayOfWeek,
    start_time: startTime,
    end_time: endTime,
    room: cleanString(row.salle) || '',
    school_year: schoolYear || row.school_year || '2024-2025',
    is_active: true
  })

  if (error) throw new Error(`Création emploi du temps: ${error.message}`)
  results.created++
}
