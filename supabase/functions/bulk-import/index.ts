// supabase/functions/bulk-import/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// ============================================
// CONFIGURATION
// ============================================
const DEFAULT_PARENT_PASSWORD = (matricule: string) => matricule;
const DEFAULT_TEACHER_PASSWORD = (prenom: string, nom: string) => 
  `${(prenom?.charAt(0) || nom.charAt(0)).toUpperCase()}${nom.toUpperCase()}`;

serve(async (req: Request) => {
  console.log('📥 REQUÊTE REÇUE:', req.method, req.url);
  console.log('📥 HEADERS:', JSON.stringify(Object.fromEntries(req.headers.entries())));

  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
  };

  if (req.method === "OPTIONS") {
    console.log('📥 OPTIONS request');
    return new Response(null, { headers, status: 204 });
  }

  try {
    const bodyText = await req.text();
    console.log('📥 BODY BRUT:', bodyText.substring(0, 500));
    
    let body;
    try {
      body = JSON.parse(bodyText);
    } catch (parseError) {
      const errorMsg = parseError instanceof Error ? parseError.message : String(parseError);
      console.log('❌ JSON parse error:', errorMsg);
      return new Response(JSON.stringify({
        success: false,
        error: 'Invalid JSON: ' + errorMsg
      }), { status: 400, headers });
    }

    const { type, data, schoolId, schoolCode } = body;
    console.log('📥 TYPE:', type, '| DATA LENGTH:', data?.length, '| SCHOOL ID:', schoolId);

    if (!type || !data || !schoolId) {
      return new Response(JSON.stringify({
        success: false,
        error: `Missing parameters: type=${type}, data=${data?.length}, schoolId=${schoolId}`
      }), { status: 400, headers });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") as string;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") as string;
    
    console.log('📥 SUPABASE URL:', supabaseUrl?.substring(0, 20) + '...');
    console.log('📥 SERVICE KEY LENGTH:', serviceRoleKey?.length);

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false }
    });

    const results = {
      created: 0,
      updated: 0,
      errors: [] as Array<{ row: number; error: string; data: any }>,
      credentials: [] as Array<{ type: string; name: string; phone: string; password: string; matricule?: string }>
    };

    for (let i = 0; i < data.length; i++) {
      const row = data[i];
      console.log(`📥 ROW ${i + 1}:`, JSON.stringify(row).substring(0, 200));
      
      try {
        if (type === "students_parents") {
          await importStudentParent(supabaseAdmin, row, schoolId, schoolCode, results);
        } else if (type === "teachers") {
          await importTeacher(supabaseAdmin, row, schoolId, schoolCode, results);
        } else if (type === "schedules") {
          await importSchedule(supabaseAdmin, row, schoolId, results);
        } else {
          throw new Error(`Unknown type: ${type}`);
        }
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : String(err);
        console.log(`❌ ROW ${i + 1} ERROR:`, errorMessage);
        results.errors.push({ row: i + 1, error: errorMessage, data: row });
      }
    }

    console.log('📥 RESULTS:', JSON.stringify(results));

    return new Response(JSON.stringify({
      success: results.errors.length === 0,
      created: results.created,
      updated: results.updated,
      errors: results.errors,
      credentials: results.credentials,
      total: data.length
    }), { headers });

  } catch (fatalError) {
    const errorMessage = fatalError instanceof Error ? fatalError.message : String(fatalError);
    console.log('❌ FATAL ERROR:', errorMessage);
    return new Response(JSON.stringify({
      success: false,
      error: errorMessage
    }), { status: 400, headers });
  }
});

// ============================================
// IMPORT ÉLÈVES & PARENTS
// ============================================
async function importStudentParent(supabaseAdmin: any, row: any, schoolId: string, schoolCode: string, results: any) {
  const matricule = row.matricule?.toString().trim().toUpperCase();
  const eleveNom = row.eleve_nom?.toString().trim();
  const elevePrenom = row.eleve_prenom?.toString().trim();
  const classeName = row.classe?.toString().trim();
  const parentNom = row.parent_nom?.toString().trim();
  const parentPrenom = row.parent_prenom?.toString().trim();
  const parentPhone = row.parent_telephone?.toString().trim();

  if (!matricule || !eleveNom || !parentPhone) {
    throw new Error("Champs obligatoires manquants (matricule, eleve_nom, parent_telephone)");
  }

  const classId = await findOrCreateClass(supabaseAdmin, schoolId, classeName);

  const { data: student, error: studentError } = await supabaseAdmin
    .from("students")
    .insert({
      school_id: schoolId,
      class_id: classId,
      matricule: matricule,
      first_name: elevePrenom || eleveNom,
      last_name: eleveNom,
      is_active: true
    })
    .select("id")
    .single();

  if (studentError) throw new Error(`Élève: ${studentError.message}`);

  const password = DEFAULT_PARENT_PASSWORD(matricule);
  const { data: hashResult, error: hashError } = await supabaseAdmin.rpc("crypt_password", {
    p_password: password
  });
  
  if (hashError || !hashResult) throw new Error(`Hash: ${hashError?.message}`);

  const { data: parentUser, error: parentError } = await supabaseAdmin
    .from("app_users")
    .insert({
      school_id: schoolId,
      email: null,
      first_name: parentPrenom || parentNom,
      last_name: parentNom,
      role: "parent",
      phone: parentPhone,
      password_hash: hashResult,
      is_active: true
    })
    .select("id")
    .single();

  if (parentError) {
    if (parentError.message.includes("duplicate") || parentError.code === "23505") {
      const { data: existing } = await supabaseAdmin
        .from("app_users")
        .select("id")
        .eq("phone", parentPhone)
        .eq("school_id", schoolId)
        .single();
      
      if (existing) {
        await createParentStudentLink(supabaseAdmin, existing.id, student.id, schoolId);
        results.updated++;
        return;
      }
    }
    throw new Error(`Parent: ${parentError.message}`);
  }

  await createParentStudentLink(supabaseAdmin, parentUser.id, student.id, schoolId);

  try {
    await supabaseAdmin.from("parent_profiles").insert({ user_id: parentUser.id });
  } catch { /* ignore */ }

  results.credentials.push({
    type: "parent",
    name: `${parentPrenom || ""} ${parentNom}`,
    phone: parentPhone,
    password: password,
    matricule: matricule
  });

  results.created++;
}

async function createParentStudentLink(supabaseAdmin: any, parentId: string, studentId: string, schoolId: string) {
  await supabaseAdmin.from("parent_students").insert({
    parent_id: parentId,
    student_id: studentId,
    relationship: "parent",
    is_primary: true,
    school_id: schoolId
  });
}

// ============================================
// IMPORT ENSEIGNANTS
// ============================================
async function importTeacher(supabaseAdmin: any, row: any, schoolId: string, schoolCode: string, results: any) {
  const nom = row.nom?.toString().trim();
  const prenom = row.prenom?.toString().trim();
  const phoneRaw = row.telephone?.toString().trim();
  const matiere = row.matiere?.toString().trim();

  if (!nom || !phoneRaw) throw new Error("Nom et téléphone obligatoires");

  const phone = phoneRaw;

  const { data: existing } = await supabaseAdmin
    .from("app_users")
    .select("id")
    .eq("phone", phone)
    .eq("school_id", schoolId)
    .maybeSingle();

  if (existing) {
    results.updated++;
    return;
  }

  const password = DEFAULT_TEACHER_PASSWORD(prenom, nom);
  
  const { data: hashResult, error: hashError } = await supabaseAdmin.rpc("crypt_password", {
    p_password: password
  });
  
  if (hashError || !hashResult) throw new Error(`Hash: ${hashError?.message}`);

  const { data: teacherUser, error: teacherError } = await supabaseAdmin
    .from("app_users")
    .insert({
      school_id: schoolId,
      email: null,
      first_name: prenom || nom,
      last_name: nom,
      role: "teacher",
      phone: phone,
      password_hash: hashResult,
      is_active: true
    })
    .select("id")
    .single();

  if (teacherError) throw new Error(`Enseignant: ${teacherError.message}`);

  try {
    await supabaseAdmin.from("teacher_profiles").insert({
      user_id: teacherUser.id,
      specialization: matiere || "",
      qualifications: []
    });
  } catch { /* ignore */ }

  results.credentials.push({
    type: "teacher",
    name: `${prenom || ""} ${nom}`,
    phone: phone,
    password: password
  });

  results.created++;
}

// ============================================
// IMPORT EMPLOI DU TEMPS - VERSION CORRIGÉE
// ============================================

/**
 * Cherche une valeur dans plusieurs clés possibles (normalisation robuste)
 */
function findColumn(row: any, possibleKeys: string[]): any {
  console.log(`🔍 findColumn: recherche parmi ${JSON.stringify(possibleKeys)}`);
  
  for (const key of possibleKeys) {
    // 1. Clé exacte
    if (row[key] !== undefined && row[key] !== null && row[key] !== '') {
      console.log(`✅ findColumn: trouvé exact "${key}" = "${row[key]}"`);
      return row[key];
    }
    
    // 2. Clé normalisée (sans accent, lowercase, underscore)
    const normalizedKey = key
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .replace(/\s+/g, '_')
      .replace(/[^a-z0-9_]/g, '');
    
    for (const [rowKey, rowValue] of Object.entries(row)) {
      const normalizedRowKey = rowKey
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .replace(/\s+/g, '_')
        .replace(/[^a-z0-9_]/g, '');
      
      if (normalizedRowKey === normalizedKey && rowValue !== undefined && rowValue !== null && rowValue !== '') {
        console.log(`✅ findColumn: trouvé normalisé "${rowKey}" -> "${normalizedKey}" = "${rowValue}"`);
        return rowValue;
      }
    }
  }
  
  console.log(`❌ findColumn: aucune clé trouvée`);
  return undefined;
}

async function importSchedule(supabaseAdmin: any, row: any, schoolId: string, results: any) {
  console.log('📥 SCHEDULE ROW RAW:', JSON.stringify(row));
  
  // --- MAPPING ROBUSTE DES COLONNES ---
  const classeName = findColumn(row, ['classe', 'class', 'classe_name', 'nom_classe', 'class_name', 'niveau', 'level']);
  const jour = findColumn(row, ['jour', 'day', 'weekday', 'jour_semaine', 'day_of_week', 'jour_de_la_semaine']);
  
  // CORRECTION PRINCIPALE : Cherche dans TOUTES les variantes d'heures
  const rawDebut = findColumn(row, [
    'start_time', 'heure_debut', 'heure_début', 'heure debut', 'heureDebut', 
    'hd', 'debut', 'debut_heure', 'heure_de_debut', 'start', 'time_start', 'debut_horaire'
  ]);
  
  const rawFin = findColumn(row, [
    'end_time', 'heure_fin', 'heure fin', 'heureFin', 
    'hf', 'fin', 'fin_heure', 'heure_de_fin', 'end', 'time_end', 'fin_horaire'
  ]);
  
  const matiere = findColumn(row, ['matiere', 'subject', 'course', 'matiere_name', 'nom_matiere', 'discipline', 'matiere_enseignee']);
  const enseignantPhone = findColumn(row, [
    'enseignant_telephone', 'teacher_phone', 'phone', 'telephone', 
    'prof', 'enseignant', 'teacher', 'professeur', 'prof_telephone', 'teacher_tel'
  ]);
  const salle = findColumn(row, ['salle', 'room', 'classroom', 'salle_classe', 'salle_de_classe', 'local']);

  console.log('🔍 RAW VALUES:', { rawDebut, rawFin, classeName, jour, matiere, enseignantPhone, salle });
  
  // --- PARSING DES HEURES ---
  const heureDebut = parseHeure(rawDebut);
  const heureFin = parseHeure(rawFin);

  console.log('📥 SCHEDULE PARSED:', { 
    classeName, jour, heureDebut, heureFin, matiere, enseignantPhone, salle 
  });

  // --- VALIDATION ---
  const missingFields: string[] = [];
  if (!classeName) missingFields.push('classe');
  if (!jour) missingFields.push('jour');
  if (!heureDebut) missingFields.push(`heure_debut(raw=${rawDebut})`);
  if (!heureFin) missingFields.push(`heure_fin(raw=${rawFin})`);
  if (!matiere) missingFields.push('matiere');
  if (!enseignantPhone) missingFields.push('enseignant_telephone');

  if (missingFields.length > 0) {
    throw new Error(`Champs manquants ou invalides: [${missingFields.join(', ')}]`);
  }

  // --- RÉCUPÈRE OU CRÉE LA CLASSE ---
  const { data: cls, error: e1 } = await supabaseAdmin
    .from("classes")
    .select("id")
    .eq("school_id", schoolId)
    .eq("name", classeName)
    .single();
  
  if (e1) throw new Error(`Classe "${classeName}": ${e1.message}`);

  // --- RÉCUPÈRE L'ENSEIGNANT ---
  const { data: tch, error: e2 } = await supabaseAdmin
    .from("app_users")
    .select("id")
    .eq("school_id", schoolId)
    .eq("phone", enseignantPhone)
    .eq("role", "teacher")
    .single();
  
  if (e2) throw new Error(`Enseignant ${enseignantPhone}: ${e2.message}`);

  // --- RÉCUPÈRE OU CRÉE LA MATIÈRE ---
  let { data: sub } = await supabaseAdmin
    .from("subjects")
    .select("id")
    .eq("school_id", schoolId)
    .eq("name", matiere)
    .maybeSingle();
  
  let subjectId = sub?.id;
  if (!subjectId) {
    const { data: newSub, error: e3 } = await supabaseAdmin
      .from("subjects")
      .insert({ 
        school_id: schoolId, 
        name: matiere, 
        code: matiere.substring(0, 3).toUpperCase() 
      })
      .select("id")
      .single();
    
    if (e3) throw new Error(`Matière: ${e3.message}`);
    subjectId = newSub.id;
  }

  // --- VÉRIFIE SI UN CRÉNEAU IDENTIQUE EXISTE DÉJÀ ---
  const { data: existingSchedule } = await supabaseAdmin
    .from("schedules")
    .select("id")
    .eq("school_id", schoolId)
    .eq("class_id", cls.id)
    .eq("day_of_week", dayToNumber(jour))
    .eq("start_time", heureDebut)
    .eq("end_time", heureFin)
    .eq("teacher_id", tch.id)
    .maybeSingle();

  const scheduleData = {
    school_id: schoolId,
    class_id: cls.id,
    teacher_id: tch.id,
    subject_id: subjectId,
    day_of_week: dayToNumber(jour),
    start_time: heureDebut,      // Format HH:MM:SS - stocké comme TIME PostgreSQL
    end_time: heureFin,          // Format HH:MM:SS - stocké comme TIME PostgreSQL
    room: salle || "",
    is_active: true,
    updated_at: new Date().toISOString()
  };

  if (existingSchedule) {
    // Mise à jour
    const { error: updateError } = await supabaseAdmin
      .from("schedules")
      .update(scheduleData)
      .eq("id", existingSchedule.id);
    
    if (updateError) throw new Error(`Mise à jour: ${updateError.message}`);
    results.updated++;
    console.log(`✅ Schedule ${existingSchedule.id} mis à jour`);
  } else {
    // Création
    const { error: insertError } = await supabaseAdmin
      .from("schedules")
      .insert(scheduleData);
    
    if (insertError) throw new Error(`Insertion: ${insertError.message}`);
    results.created++;
    console.log('✅ Schedule créé');
  }
}

// ============================================
// FONCTIONS UTILITAIRES - PARSING HEURE ULTRA-ROBUSTE
// ============================================

/**
 * Parse n'importe quel format d'heure en HH:MM:SS
 * 
 * Formats supportés:
 * - "08:10:00" (HH:MM:SS)
 * - "08:10" (HH:MM)
 * - "8:10" (H:MM)
 * - "8h10" / "8H10" / "8h10min"
 * - "0810" (4 chiffres)
 * - 0.340277 (Excel fraction de jour)
 * - "2024-01-15T08:10:00" (ISO datetime)
 * - "8.10" (format point)
 * - "8:10 AM" / "8:10 PM"
 * 
 * Retourne null si invalide (permet de distinguer échec parsing vs valeur vide)
 */
function parseHeure(value: any): string | null {
  console.log('🔍 parseHeure input:', value, 'type:', typeof value);
  
  if (value === undefined || value === null || value === '') {
    console.log('🔍 parseHeure: empty/null/undefined');
    return null;
  }
  
  // --- NOMBRE (format Excel) ---
  if (typeof value === 'number') {
    console.log('🔍 parseHeure: number =', value);
    
    // Format Excel: fraction de jour (ex: 0.340277 = 08:10:00)
    if (value > 0 && value < 1) {
      const totalSeconds = Math.round(value * 24 * 60 * 60);
      const hours = Math.floor(totalSeconds / 3600);
      const minutes = Math.floor((totalSeconds % 3600) / 60);
      const seconds = totalSeconds % 60;
      const result = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
      console.log('🔍 parseHeure: Excel fraction ->', result);
      return result;
    }
    
    // Nombre entier: 810 -> 08:10:00, 1430 -> 14:30:00
    const str = Math.floor(value).toString().padStart(4, '0');
    if (str.length === 4) {
      const hours = parseInt(str.substring(0, 2));
      const minutes = parseInt(str.substring(2, 4));
      if (hours <= 23 && minutes <= 59) {
        const result = `${str.substring(0, 2)}:${str.substring(2)}:00`;
        console.log('🔍 parseHeure: Number HHMM ->', result);
        return result;
      }
    }
    
    console.log('🔍 parseHeure: Number non reconnu');
    return null;
  }
  
  let s = value.toString().trim();
  console.log('🔍 parseHeure string:', s);
  
  // --- DÉJÀ AU FORMAT HH:MM:SS ---
  if (/^\d{2}:\d{2}:\d{2}$/.test(s)) {
    const [h, m, sec] = s.split(':').map(Number);
    if (h >= 0 && h <= 23 && m >= 0 && m <= 59 && sec >= 0 && sec <= 59) {
      console.log('🔍 parseHeure: format HH:MM:SS ✓');
      return s;
    }
  }
  
  // --- FORMAT HH:MM ---
  if (/^\d{2}:\d{2}$/.test(s)) {
    const [h, m] = s.split(':').map(Number);
    if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
      console.log('🔍 parseHeure: format HH:MM ✓');
      return `${s}:00`;
    }
  }
  
  // --- FORMAT H:MM (ex: 8:10) ---
  if (/^\d{1}:\d{2}$/.test(s)) {
    const [h, m] = s.split(':').map(Number);
    if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
      const result = `0${s}:00`;
      console.log('🔍 parseHeure: format H:MM ✓ ->', result);
      return result;
    }
  }
  
  // --- FORMAT ISO DATETIME (2024-01-15T08:10:00) ---
  if (s.includes('T')) {
    const timePart = s.split('T')[1];
    if (/^\d{2}:\d{2}:\d{2}/.test(timePart)) {
      const result = timePart.substring(0, 8);
      console.log('🔍 parseHeure: format ISO ✓ ->', result);
      return result;
    }
  }
  
  // --- FORMAT AVEC POINT (8.10 -> 08:10:00) ---
  if (/^\d{1,2}\.\d{2}$/.test(s)) {
    const [h, m] = s.split('.');
    const hours = parseInt(h);
    const minutes = parseInt(m);
    if (hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59) {
      const result = `${h.padStart(2, '0')}:${m}:00`;
      console.log('🔍 parseHeure: format point ✓ ->', result);
      return result;
    }
  }
  
  // --- FORMAT AVEC H (8h10, 8H10, 8h10min) ---
  const hMatch = s.match(/^(\d{1,2})[hH](\d{2})(?:min)?$/);
  if (hMatch) {
    const hours = parseInt(hMatch[1]);
    const minutes = parseInt(hMatch[2]);
    if (hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59) {
      const result = `${hMatch[1].padStart(2, '0')}:${hMatch[2]}:00`;
      console.log('🔍 parseHeure: format HeureMinute ✓ ->', result);
      return result;
    }
  }
  
  // --- FORMAT 4 CHIFFRES (0810) ---
  if (/^\d{4}$/.test(s)) {
    const hours = parseInt(s.substring(0, 2));
    const minutes = parseInt(s.substring(2, 4));
    if (hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59) {
      const result = `${s.substring(0, 2)}:${s.substring(2)}:00`;
      console.log('🔍 parseHeure: format 4 chiffres ✓ ->', result);
      return result;
    }
  }
  
  // --- FORMAT AM/PM (8:10 AM, 2:30 PM) ---
  const ampmMatch = s.match(/^(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)$/);
  if (ampmMatch) {
    let hours = parseInt(ampmMatch[1]);
    const minutes = parseInt(ampmMatch[2]);
    const period = ampmMatch[3].toUpperCase();
    
    if (period === 'PM' && hours !== 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;
    
    if (hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59) {
      const result = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`;
      console.log('🔍 parseHeure: format AM/PM ✓ ->', result);
      return result;
    }
  }
  
  // --- FORMAT AVEC ESPACE ET MOTS (8 h 10, 14 heures 30) ---
  const wordMatch = s.match(/^(\d{1,2})\s*[hH]\s*(\d{2})(?:\s*min)?$/);
  if (wordMatch) {
    const hours = parseInt(wordMatch[1]);
    const minutes = parseInt(wordMatch[2]);
    if (hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59) {
      const result = `${wordMatch[1].padStart(2, '0')}:${wordMatch[2]}:00`;
      console.log('🔍 parseHeure: format avec espaces ✓ ->', result);
      return result;
    }
  }
  
  console.log('🔍 parseHeure: AUCUN FORMAT RECONNU ❌');
  return null;
}

/**
 * Convertit un jour en nombre (0=dimanche, 1=lundi, ..., 6=samedi)
 * Supporte: français, anglais, abréviations
 */
function dayToNumber(day: string): number {
  if (!day) return 1; // Default lundi
  
  const d = day.toString().trim().toLowerCase();
  
  // Français
  const frDays: Record<string, number> = {
    'dimanche': 0, 'dim': 0, 'di': 0,
    'lundi': 1, 'lun': 1, 'lu': 1,
    'mardi': 2, 'mar': 2, 'ma': 2,
    'mercredi': 3, 'mer': 3, 'me': 3,
    'jeudi': 4, 'jeu': 4, 'je': 4,
    'vendredi': 5, 'ven': 5, 've': 5,
    'samedi': 6, 'sam': 6, 'sa': 6
  };
  
  // Anglais
  const enDays: Record<string, number> = {
    'sunday': 0, 'sun': 0, 'su': 0,
    'monday': 1, 'mon': 1, 'mo': 1,
    'tuesday': 2, 'tue': 2, 'tu': 2,
    'wednesday': 3, 'wed': 3, 'we': 3,
    'thursday': 4, 'thu': 4, 'th': 4,
    'friday': 5, 'fri': 5, 'fr': 5,
    'saturday': 6, 'sat': 6, 'sa': 6
  };
  
  // Nombre direct
  if (/^\d$/.test(d) && parseInt(d) >= 0 && parseInt(d) <= 6) {
    return parseInt(d);
  }
  
  return frDays[d] ?? enDays[d] ?? 1; // Default lundi
}

// ============================================
// FONCTIONS UTILITAIRES GÉNÉRALES
// ============================================

async function findOrCreateClass(supabaseAdmin: any, schoolId: string, className: string) {
  const { data: existing } = await supabaseAdmin
    .from("classes")
    .select("id")
    .eq("school_id", schoolId)
    .eq("name", className)
    .maybeSingle();

  if (existing) return existing.id;

  const { data: newClass, error } = await supabaseAdmin
    .from("classes")
    .insert({
      school_id: schoolId,
      name: className,
      level: className.split(" ")[0],
      is_active: true
    })
    .select("id")
    .single();

  if (error) throw new Error(`Classe: ${error.message}`);
  return newClass.id;
}