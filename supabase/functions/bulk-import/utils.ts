// supabase/functions/bulk-import/utils.ts

export function normalizePhone(phone: string | null | undefined): string | null {
  if (!phone) return null
  
  const cleaned = phone.toString()
    .replace(/\s/g, '')
    .replace(/[.\-]/g, '')
    .trim()
  
  if (cleaned.startsWith('+')) {
    if (!/^\+\d{10,15}$/.test(cleaned)) {
      throw new Error(`Format téléphone invalide: ${phone}`)
    }
    return cleaned
  }
  
  if (cleaned.startsWith('0') && cleaned.length === 10) {
    return '+33' + cleaned.substring(1)
  }
  
  if (/^\d{9}$/.test(cleaned)) {
    return '+33' + cleaned
  }
  
  throw new Error(`Format téléphone non reconnu: ${phone}`)
}

export function cleanString(value: any, required: boolean = false): string {
  if (value === null || value === undefined) {
    if (required) throw new Error('Champ requis manquant')
    return ''
  }
  const cleaned = value.toString().trim()
  if (required && cleaned === '') {
    throw new Error('Champ ne peut pas être vide')
  }
  return cleaned
}

export function generateTempEmail(phone: string): string {
  return `parent_${phone.replace('+', '')}_${Date.now()}_${Math.random().toString(36).substring(2, 8)}@educonnect.temp`
}

export function getLevelOrder(levelName: string): number {
  const orderMap: Record<string, number> = {
    '6ème': 0, '6eme': 0, '6e': 0, '6': 0,
    '5ème': 1, '5eme': 1, '5e': 1, '5': 1,
    '4ème': 2, '4eme': 2, '4e': 2, '4': 2,
    '3ème': 3, '3eme': 3, '3e': 3, '3': 3,
    '2nde': 4, '2nd': 4, '2de': 4, '2': 4,
    '1ère': 5, '1ere': 5, '1re': 5, '1': 5,
    'terminale': 6, 'Terminale': 6, 'tle': 6, 'Tle': 6
  }
  return orderMap[levelName] ?? 99
}

export function dayToNumber(day: string): number {
  const dayMap: Record<string, number> = {
    'dimanche': 0, 'Dimanche': 0, 'di': 0, 'Di': 0,
    'lundi': 1, 'Lundi': 1, 'lu': 1, 'Lu': 1,
    'mardi': 2, 'Mardi': 2, 'ma': 2, 'Ma': 2,
    'mercredi': 3, 'Mercredi': 3, 'me': 3, 'Me': 3,
    'jeudi': 4, 'Jeudi': 4, 'je': 4, 'Je': 4,
    'vendredi': 5, 'Vendredi': 5, 've': 5, 'Ve': 5,
    'samedi': 6, 'Samedi': 6, 'sa': 6, 'Sa': 6
  }
  
  const result = dayMap[day]
  if (result === undefined) {
    const num = parseInt(day)
    if (!isNaN(num) && num >= 0 && num <= 6) return num
    throw new Error(`Jour non reconnu: ${day}`)
  }
  return result
}

export function validateTime(time: string): string {
  if (!time) throw new Error('Heure requise')
  
  let normalized = time.toString().trim()
  
  if (/^\d{1,2}$/.test(normalized)) {
    normalized = normalized.padStart(2, '0') + ':00'
  }
  
  const match = normalized.match(/^(\d{1,2})[:hH](\d{2})$/)
  if (!match) throw new Error(`Format heure invalide: ${time}`)
  
  const hours = parseInt(match[1])
  const minutes = parseInt(match[2])
  
  if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
    throw new Error(`Heure invalide: ${time}`)
  }
  
  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
}