import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { reportType, data, format, schoolId } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    let fileBuffer: Uint8Array;
    let contentType: string;
    let fileExtension: string;

    if (format === "excel") {
      // Générer CSV simple (Excel peut l'ouvrir)
      const csv = generateCSV(data, reportType);
      fileBuffer = new TextEncoder().encode(csv);
      contentType = "text/csv";
      fileExtension = "csv";
    } else if (format === "pdf" || format === "word") {
      // Générer HTML (ouvert par Word et navigateurs)
      const html = generateHTML(data, reportType);
      fileBuffer = new TextEncoder().encode(html);
      contentType = "text/html";
      fileExtension = format === "pdf" ? "html" : "html";
    } else {
      throw new Error("Format non supporté");
    }

    // Nom de fichier unique
    const timestamp = Date.now();
    const fileName = `rapport_${reportType}_${timestamp}.${fileExtension}`;

    // Upload vers Supabase Storage
    const { data: uploadData, error: uploadError } = await supabase
      .storage
      .from("reports")
      .upload(fileName, fileBuffer, {
        contentType,
        upsert: false,
      });

    if (uploadError) throw uploadError;

    // URL signée (valide 1 heure)
    const { data: urlData } = await supabase
      .storage
      .from("reports")
      .createSignedUrl(fileName, 3600);

    return new Response(
      JSON.stringify({
        success: true,
        fileUrl: urlData?.signedUrl,
        fileName,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

function generateCSV(data: any[], reportType: string): string {
  if (!data || data.length === 0) return "Aucune donnée";

  const headers = [
    "Date",
    reportType === "attendance" ? "Cours" : "Classe",
    reportType === "attendance" ? "Horaire" : "Élève",
    reportType === "attendance" ? "Classe" : "Matière",
    reportType === "attendance" ? "Élève" : "Coefficient",
    reportType === "attendance" ? "Enseignant" : "Note",
    reportType === "attendance" ? "Statut" : "",
  ];

  let csv = headers.join(";") + "\n";

  for (const row of data) {
    const values = [
      formatDate(row.date),
      reportType === "attendance" 
        ? row.schedules?.subjects?.name ?? "-" 
        : `${row.classes?.level ?? ""} ${row.classes?.name ?? ""}`,
      reportType === "attendance"
        ? `${row.schedules?.start_time ?? "--:--"}-${row.schedules?.end_time ?? "--:--"}`
        : `${row.students?.last_name ?? ""} ${row.students?.first_name ?? ""}`,
      reportType === "attendance"
        ? `${row.schedules?.classes?.level ?? ""} ${row.schedules?.classes?.name ?? ""}`
        : row.subjects?.name ?? "-",
      reportType === "attendance"
        ? `${row.students?.last_name ?? ""} ${row.students?.first_name ?? ""}`
        : String(row.coefficient ?? 1),
      reportType === "attendance"
        ? `${row.teachers?.last_name ?? ""} ${row.teachers?.first_name ?? ""}`
        : `${calculateNote(row).toFixed(1)}/20`,
      reportType === "attendance" ? (row.status ?? "-") : "",
    ];
    csv += values.join(";") + "\n";
  }

  return csv;
}

function generateHTML(data: any[], reportType: string): string {
  if (!data || data.length === 0) return "<h1>Aucune donnée</h1>";

  const title = reportType === "attendance" ? "Rapport d'Assiduité" : "Rapport de Notes";
  const now = new Date().toLocaleString("fr-FR");

  let html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>${title}</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; color: #333; }
        h1 { color: #6B4EFF; border-bottom: 2px solid #6B4EFF; padding-bottom: 10px; }
        .meta { color: #666; margin-bottom: 20px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #6B4EFF; color: white; padding: 10px; text-align: left; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f8f9fe; }
        .status-present { color: green; font-weight: bold; }
        .status-absent { color: red; font-weight: bold; }
        .status-late { color: orange; font-weight: bold; }
        .note-green { color: green; font-weight: bold; }
        .note-orange { color: orange; font-weight: bold; }
        .note-red { color: red; font-weight: bold; }
      </style>
    </head>
    <body>
      <h1>${title}</h1>
      <p class="meta">Généré le ${now} • ${data.length} enregistrements</p>
      <table>
        <thead>
          <tr>
  `;

  if (reportType === "attendance") {
    html += `
            <th>Date</th>
            <th>Cours</th>
            <th>Horaire</th>
            <th>Classe</th>
            <th>Élève</th>
            <th>Enseignant</th>
            <th>Statut</th>
          </tr>
        </thead>
        <tbody>
    `;
    for (const row of data) {
      const status = row.status ?? "-";
      const statusClass = status === "present" ? "status-present" : status === "absent" ? "status-absent" : status === "late" ? "status-late" : "";
      const statusLabel = status === "present" ? "Présent" : status === "absent" ? "Absent" : status === "late" ? "Retard" : "-";
      
      html += `
          <tr>
            <td>${formatDate(row.date)}</td>
            <td>${row.schedules?.subjects?.name ?? "-"}</td>
            <td>${row.schedules?.start_time ?? "--:--"}-${row.schedules?.end_time ?? "--:--"}</td>
            <td>${row.schedules?.classes?.level ?? ""} ${row.schedules?.classes?.name ?? ""}</td>
            <td>${row.students?.last_name ?? ""} ${row.students?.first_name ?? ""}</td>
            <td>${row.teachers?.last_name ?? ""} ${row.teachers?.first_name ?? ""}</td>
            <td class="${statusClass}">${statusLabel}</td>
          </tr>
      `;
    }
  } else {
    html += `
            <th>Date</th>
            <th>Classe</th>
            <th>Élève</th>
            <th>Matière</th>
            <th>Coefficient</th>
            <th>Note</th>
          </tr>
        </thead>
        <tbody>
    `;
    for (const row of data) {
      const note = calculateNote(row);
      const noteClass = note >= 14 ? "note-green" : note >= 10 ? "note-orange" : "note-red";
      
      html += `
          <tr>
            <td>${formatDate(row.date)}</td>
            <td>${row.classes?.level ?? ""} ${row.classes?.name ?? ""}</td>
            <td>${row.students?.last_name ?? ""} ${row.students?.first_name ?? ""}</td>
            <td>${row.subjects?.name ?? "-"}</td>
            <td>${row.coefficient ?? 1}</td>
            <td class="${noteClass}">${note.toFixed(1)}/20</td>
          </tr>
      `;
    }
  }

  html += `
        </tbody>
      </table>
    </body>
    </html>
  `;

  return html;
}

function formatDate(dateStr: string): string {
  if (!dateStr) return "-";
  const date = new Date(dateStr);
  return `${date.getDate()}/${date.getMonth() + 1}`;
}

function calculateNote(row: any): number {
  const score = row.score ?? 0;
  const maxScore = row.max_score ?? 20;
  return maxScore > 0 ? (score / maxScore) * 20 : 0;
}