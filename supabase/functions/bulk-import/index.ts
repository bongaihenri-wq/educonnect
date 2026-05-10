import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req: Request) => {
  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { headers, status: 204 });
  }

  try {
    const { type, data, schoolId, schoolCode } = await req.json();

    const supabaseUrl = Deno.env.get("SUPABASE_URL") as string;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") as string;
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
      
      try {
        if (type === "students_parents") {
          await importStudentParent(supabaseAdmin, row, schoolId, schoolCode, results);
        } else if (type === "teachers") {
          await importTeacher(supabaseAdmin, row, schoolId, schoolCode, results);
        } else if (type === "schedules") {
          await importSchedule(supabaseAdmin, row, schoolId, results);
        }
      } catch (e: any) {
        results.errors.push({ row: i + 1, error: e.message, data: row });
      }
    }

    return new Response(JSON.stringify({
      success: results.errors.length === 0,
      created: results.created,
      updated: results.updated,
      errors: results.errors,
      credentials: results.credentials,
      total: data.length
    }), { headers });

  } catch (error: any) {
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), { status: 400, headers });
  }
});

// ========== IMPORT ÉLÈVES & PARENTS ==========
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

  // 1. Trouver ou créer la classe
  const classId = await findOrCreateClass(supabaseAdmin, schoolId, classeName);

  // 2. Créer l'élève dans students
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

  if (studentError) throw new Error(`Erreur creation eleve: ${studentError.message}`);

  // 3. Générer mot de passe et hash
  const password = `${matricule}Edu2024!`;
  const { data: hashResult } = await supabaseAdmin.rpc("crypt_password", {
    p_password: password
  });

  // 4. Créer le parent dans app_users DIRECTEMENT
  const { data: parentUser, error: parentError } = await supabaseAdmin
    .from("app_users")
    .insert({
      school_id: schoolId,
      email: null,                    // ⭐ PAS d'email pour les parents
      first_name: parentPrenom || parentNom,
      last_name: parentNom,
      role: "parent",
      phone: parentPhone,             // ⭐ Téléphone = identifiant de connexion
      password_hash: hashResult,
      is_active: true
    })
    .select("id")
    .single();

  if (parentError) {
    if (parentError.message.includes("duplicate")) {
      const { data: existing } = await supabaseAdmin
        .from("app_users")
        .select("id")
        .eq("phone", parentPhone)     // ⭐ Recherche par téléphone
        .eq("school_id", schoolId)
        .single();
      
      if (existing) {
        await createParentStudentLink(supabaseAdmin, existing.id, student.id, schoolId);
        results.updated++;
        return;
      }
    }
    throw new Error(`Erreur creation parent: ${parentError.message}`);
  }

  // 5. Créer le lien parent-élève
  await createParentStudentLink(supabaseAdmin, parentUser.id, student.id, schoolId);

  // 6. Créer parent_profiles vide
  await supabaseAdmin.from("parent_profiles").insert({
    user_id: parentUser.id
  });

  // 7. Sauvegarder credentials pour rapport ⭐ CORRIGÉ
  results.credentials.push({
    type: "parent",
    name: `${parentPrenom || ""} ${parentNom}`,
    phone: parentPhone,              // ⭐ Téléphone = login
    password: password,
    matricule: matricule             // ⭐ Matricule ajouté
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

// ========== IMPORT ENSEIGNANTS ==========
async function importTeacher(supabaseAdmin: any, row: any, schoolId: string, schoolCode: string, results: any) {
  const nom = row.nom?.toString().trim();
  const prenom = row.prenom?.toString().trim();
  const email = row.email?.toString().trim().toLowerCase();
  const phone = row.telephone?.toString().trim();
  const matiere = row.matiere?.toString().trim();

  if (!nom || !phone) {              // ⭐ Téléphone obligatoire (pas email)
    throw new Error("Nom et telephone obligatoires");
  }

  // 1. Vérifier si l'enseignant existe déjà (par téléphone)
  const { data: existing } = await supabaseAdmin
    .from("app_users")
    .select("id")
    .eq("phone", phone)              // ⭐ Recherche par téléphone
    .eq("school_id", schoolId)
    .maybeSingle();

  if (existing) {
    results.updated++;
    return;
  }

  // 2. Générer mot de passe et hash
  const password = `${prenom?.charAt(0) || "A"}${nom.toLowerCase()}@2024`;
  const { data: hashResult } = await supabaseAdmin.rpc("crypt_password", {
    p_password: password
  });

  // 3. Créer dans app_users DIRECTEMENT ⭐ CORRIGÉ
  const { data: teacherUser, error: teacherError } = await supabaseAdmin
    .from("app_users")
    .insert({
      school_id: schoolId,
      email: null,                    // ⭐ PAS d'email pour les enseignants non plus
      first_name: prenom || nom,
      last_name: nom,
      role: "teacher",
      phone: phone,                   // ⭐ Téléphone = identifiant de connexion
      password_hash: hashResult,
      is_active: true
    })
    .select("id")
    .single();

  if (teacherError) throw new Error(`Erreur creation enseignant: ${teacherError.message}`);

  // 4. Créer teacher_profiles
  await supabaseAdmin.from("teacher_profiles").insert({
    user_id: teacherUser.id,
    specialization: matiere || "",
    qualifications: []
  });

  // 5. Sauvegarder credentials ⭐ CORRIGÉ
  results.credentials.push({
    type: "teacher",
    name: `${prenom || ""} ${nom}`,
    phone: phone,                    // ⭐ Téléphone au lieu d'email
    password: password
    // Pas de matricule pour l'enseignant
  });

  results.created++;
}

// ========== IMPORT EMPLOI DU TEMPS ==========
async function importSchedule(supabaseAdmin: any, row: any, schoolId: string, results: any) {
  const classeName = row.classe?.toString().trim();
  const jour = row.jour?.toString().trim();
  const heureDebut = row.heure_debut?.toString().trim();
  const heureFin = row.heure_fin?.toString().trim();
  const matiere = row.matiere?.toString().trim();
  const enseignantPhone = row.enseignant_telephone?.toString().trim();  // ⭐ Par téléphone
  const salle = row.salle?.toString().trim();

  // Trouver les IDs
  const { data: classe } = await supabaseAdmin
    .from("classes")
    .select("id")
    .eq("school_id", schoolId)
    .eq("name", classeName)
    .single();

  // ⭐ Recherche enseignant par téléphone (pas email)
  const { data: teacher } = await supabaseAdmin
    .from("app_users")
    .select("id")
    .eq("school_id", schoolId)
    .eq("phone", enseignantPhone)
    .eq("role", "teacher")
    .single();

  const { data: subject } = await supabaseAdmin
    .from("subjects")
    .select("id")
    .eq("school_id", schoolId)
    .eq("name", matiere)
    .maybeSingle();

  let subjectId = subject?.id;
  if (!subjectId) {
    const { data: newSubject } = await supabaseAdmin
      .from("subjects")
      .insert({ 
        school_id: schoolId, 
        name: matiere, 
        code: matiere.substring(0, 3).toUpperCase() 
      })
      .select("id")
      .single();
    subjectId = newSubject.id;
  }

  // Créer le schedule
  await supabaseAdmin.from("schedules").insert({
    school_id: schoolId,
    class_id: classe.id,
    teacher_id: teacher.id,
    subject_id: subjectId,
    day_of_week: dayToNumber(jour),
    start_time: heureDebut,
    end_time: heureFin,
    room: salle || "",
    is_active: true
  });

  results.created++;
}

// ========== UTILITAIRES ==========
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

  if (error) throw new Error(`Erreur creation classe: ${error.message}`);
  return newClass.id;
}

function dayToNumber(day: string): number {
  const days: Record<string, number> = {
    dimanche: 0, lundi: 1, mardi: 2, mercredi: 3,
    jeudi: 4, vendredi: 5, samedi: 6
  };
  return days[day.toLowerCase()] || 1;
}