import { i18n, intl } from '@kit.LocalizationKit';

export function formatDate(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    const locale = i18n.System.getSystemLocale();
    return new intl.DateTimeFormat(locale, { dateStyle: 'medium' }).format(date);
  } catch (e) {
    return dateStr.substring(0, dateStr.indexOf('T'));
  }
}

export function formatTime(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    const locale = i18n.System.getSystemLocale();
    return new intl.DateTimeFormat(locale, { timeStyle: 'medium' }).format(date);
  } catch (e) {
    return dateStr.substring(dateStr.indexOf('T') + 1, dateStr.lastIndexOf('.'));
  }
}

export function formatDatetime(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    const locale = i18n.System.getSystemLocale();
    return new intl.DateTimeFormat(locale, { dateStyle: 'medium', timeStyle: 'medium' }).format(date);
  } catch (e) {
    return dateStr;
  }
}
