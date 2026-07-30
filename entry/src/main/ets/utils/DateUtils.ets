import { i18n } from '@kit.LocalizationKit';

export function formatDate(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    const locale = i18n.System.getSystemLocaleInstance().toString();
    return new Intl.DateTimeFormat(locale, { dateStyle: 'medium' }).format(date);
  } catch (e) {
    const tIdx = dateStr.indexOf('T');
    return tIdx > 0 ? dateStr.substring(0, tIdx) : dateStr;
  }
}

export function formatTime(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    const locale = i18n.System.getSystemLocaleInstance().toString();
    return new Intl.DateTimeFormat(locale, { timeStyle: 'medium', hour12: false }).format(date);
  } catch (e) {
    const tIdx = dateStr.indexOf('T');
    const dIdx = dateStr.lastIndexOf('.');
    if (tIdx < 0 || dIdx < 0 || dIdx <= tIdx) {
      return dateStr;
    }
    return dateStr.substring(tIdx + 1, dIdx);
  }
}

export function formatDatetime(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    const locale = i18n.System.getSystemLocaleInstance().toString();
    return new Intl.DateTimeFormat(locale, {
      dateStyle: 'medium',
      timeStyle: 'medium',
      hour12: false
    }).format(date);
  } catch (e) {
    return dateStr;
  }
}
