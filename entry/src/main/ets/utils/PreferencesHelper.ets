import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'limi_preferences';

export class PreferencesHelper {
  private static store: preferences.Preferences | null = null;

  static init(context: common.Context): void {
    PreferencesHelper.store = preferences.getPreferencesSync(context, { name: STORE_NAME });
  }

  static getBoolean(key: string, defaultValue: boolean): boolean {
    if (PreferencesHelper.store === null) {
      return defaultValue;
    }
    return PreferencesHelper.store.getSync(key, defaultValue) as boolean;
  }

  static setBoolean(key: string, value: boolean): void {
    if (PreferencesHelper.store === null) {
      return;
    }
    PreferencesHelper.store.putSync(key, value);
    PreferencesHelper.store.flush();
  }

  static getString(key: string, defaultValue: string): string {
    if (PreferencesHelper.store === null) {
      return defaultValue;
    }
    return PreferencesHelper.store.getSync(key, defaultValue) as string;
  }

  static setString(key: string, value: string): void {
    if (PreferencesHelper.store === null) {
      return;
    }
    PreferencesHelper.store.putSync(key, value);
    PreferencesHelper.store.flush();
  }
}
