import { LimiHistory } from '../data/model/LimiHistory';
import { HistoryDB } from './HistoryDB';
import { PreferencesHelper } from './PreferencesHelper';
import { RuleIds } from '../logic/Rule';

export function formatNowAsDatetime(): string {
  const now = new Date();
  const yyyy = now.getFullYear();
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const dd = String(now.getDate()).padStart(2, '0');
  const hh = String(now.getHours()).padStart(2, '0');
  const mi = String(now.getMinutes()).padStart(2, '0');
  const ss = String(now.getSeconds()).padStart(2, '0');
  const ms = String(now.getMilliseconds()).padStart(3, '0');
  return `${yyyy}-${mm}-${dd}T${hh}:${mi}:${ss}.${ms}`;
}

export async function saveHistoryIfEnabled(originalText: string, processedText: string): Promise<boolean> {
  if (originalText.length === 0 || processedText.length === 0) {
    return false;
  }
  const incognito = PreferencesHelper.getBoolean(RuleIds.INCOGNITO_MODE, false);
  if (incognito) {
    return false;
  }
  const datetime = formatNowAsDatetime();
  const history = LimiHistory.create(originalText, processedText, datetime);
  await HistoryDB.insert(history);
  return true;
}
