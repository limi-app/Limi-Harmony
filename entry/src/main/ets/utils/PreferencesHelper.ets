import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const STORE_NAME: string = 'limi_preferences';

export class PreferencesHelper {
  private static store: preferences.Preferences | null = null;

  static async init(context: common.Context): Promise<void> {
    PreferencesHelper.store = preferences.getPreferencesSync(context, { name: STORE_NAME });
  }

  static async getBoolean(key: string, defaultValue: boolean): Promise<boolean> {
    if (PreferencesHelper.store === null) {
      return defaultValue;
    }
    return PreferencesHelper.store.getSync(key, defaultValue) as boolean;
  }

  static getBooleanSync(key: string, defaultValue: boolean): boolean {
    if (PreferencesHelper.store === null) {
      return defaultValue;
    }
    return PreferencesHelper.store.getSync(key, defaultValue) as boolean;
  }

  static async setBoolean(key: string, value: boolean): Promise<void> {
    if (PreferencesHelper.store === null) {
      return;
    }
    PreferencesHelper.store.putSync(key, value);
    await PreferencesHelper.store.flush();
  }

  static async getString(key: string, defaultValue: string): Promise<string> {
    if (PreferencesHelper.store === null) {
      return defaultValue;
    }
    return PreferencesHelper.store.getSync(key, defaultValue) as string;
  }

  static async setString(key: string, value: string): Promise<void> {
    if (PreferencesHelper.store === null) {
      return;
    }
    PreferencesHelper.store.putSync(key, value);
    await PreferencesHelper.store.flush();
  }
}
