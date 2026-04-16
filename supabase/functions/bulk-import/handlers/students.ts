// supabase/functions/bulk-import/handlers/students.ts
import { cleanString, normalizePhone, generateTempEmail, getLevelOrder } from '../utils.ts'

export async function handleStudents(
  supabaseAdmin: any,
  row: any,
  schoolId: string,
  schoolCode: string,
  results: any
): Promise<void> {
  const niveau = cleanString(row.niveau, true)
  const classe = cleanString(row.classe, true)
  const elevePrenom = cleanString(row.eleve_prenom, true)
  const eleveNom = cleanString(row.eleve_nom, true)
  const matricule = cleanString(row.matricule, true).toUpperCase()
  const parentPrenom = cleanString(row.parent_prenom, true)
  const parentNom = cleanString(row.parent_nom, true)
  const parentPhone = normalizePhone(row.parent_telephone)
  
  if (!parentPhone) throw new Error('Téléphone parent requis')

  // Créer parent
  const tempEmail = generateTempEmail(parentPhone)
  const password = `${matricule}Edu2024!`

  const { data: rpcResult, error: rpcError } = await supabaseAdmin.rpc('create_parent_user', {
    p_email: tempEmail,
    p_first_name: parentPrenom,
    p_last_name: parentNom,
    p_phone: parentPhone,
    p_school_api_key: schoolCode,
    p_school_id: schoolId,
    p_password: password
  })

  if (rpcError || !rpcResult?.success) {
    throw new Error(`Création parent: ${rpcError?.message || rpcResult?.error}`)
  }

  const parentUserId = rpcResult.user_id
  rpcResult.existing ? results.updated++ : results.created++

  // Niveau
  let levelId: string
  const { data: existingLevel } = await supabaseAdmin
    .from('levels')
    .select('id')
    .eq('name', niveau)
    .eq('school_id', schoolId)
    .maybeSingle()

  if (existingLevel) {
    levelId = existingLevel.id
  } else {
    const { data: newLevel, error } = await supabaseAdmin
      .from('levels')
      .insert({ name: niveau, school_id: schoolId, order_index: getLevelOrder(niveau) })
      .select('id')
      .single()
    if (error) throw error
    levelId = newLevel!.id
  }

  // Classe
  const className = `${niveau} ${classe}`.trim()
  let classId: string
  const { data: existingClass } = await supabaseAdmin
    .from('classes')
    .select('id')
    .eq('name', className)
    .eq('school_id', schoolId)
    .maybeSingle()

  if (existingClass) {
    classId = existingClass.id
  } else {
    const { data: newClass, error } = await supabaseAdmin
      .from('classes')
      .insert({ name: className, level_id: levelId, school_id: schoolId, capacity: 30 })
      .select('id')
      .single()
    if (error) throw error
    classId = newClass!.id
  }

  // Doublon élève
  const { data: existingStudent } = await supabaseAdmin
    .from('students')
    .select('id')
    .eq('matricule', matricule)
    .eq('school_id', schoolId)
    .maybeSingle()

  if (existingStudent) {
    await supabaseAdmin.from('parent_students').delete().eq('student_id', existingStudent.id)
    await supabaseAdmin.from('students').delete().eq('id', existingStudent.id)
    results.deleted++
  }

  // Créer élève
  const { data: studentData, error: studentErr } = await supabaseAdmin
    .from('students')
    .insert({
      school_id: schoolId,
      class_id: classId,
      matricule: matricule,
      first_name: elevePrenom,
      last_name: eleveNom,
      birth_date: row.birth_date || '2010-01-01',
      gender: row.gender?.toString().toUpperCase() === 'F' ? 'F' : 'M'
    })
    .select('id')
    .single()

  if (studentErr) throw new Error(`Création élève: ${studentErr.message}`)

  // Lien parent-élève
  await supabaseAdmin.from('parent_students').insert({ 
    parent_id: parentUserId, 
    student_id: studentData.id,
    relationship: 'parent',
    is_primary: true
  })
}