import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const STORE_NAME: string = 'limi_preferences';

export class PreferencesHelper {
  private static store: preferences.Preferences | null = null;

  static init(context: common.Context): void {
    try {
      PreferencesHelper.store = preferences.getPreferencesSync(context, { name: STORE_NAME });
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PreferencesHelper', `init failed: ${err.code} ${err.message}`);
    }
  }

  static getBoolean(key: string, defaultValue: boolean): boolean {
    if (PreferencesHelper.store === null) {
      return defaultValue;
    }
    try {
      return PreferencesHelper.store.getSync(key, defaultValue) as boolean;
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PreferencesHelper', `getBoolean failed: ${err.code} ${err.message}`);
      return defaultValue;
    }
  }

  static setBoolean(key: string, value: boolean): void {
    if (PreferencesHelper.store === null) {
      return;
    }
    try {
      PreferencesHelper.store.putSync(key, value);
      PreferencesHelper.store.flush();
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PreferencesHelper', `setBoolean failed: ${err.code} ${err.message}`);
    }
  }

  static getString(key: string, defaultValue: string): string {
    if (PreferencesHelper.store === null) {
      return defaultValue;
    }
    try {
      return PreferencesHelper.store.getSync(key, defaultValue) as string;
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PreferencesHelper', `getString failed: ${err.code} ${err.message}`);
      return defaultValue;
    }
  }

  static setString(key: string, value: string): void {
    if (PreferencesHelper.store === null) {
      return;
    }
    try {
      PreferencesHelper.store.putSync(key, value);
      PreferencesHelper.store.flush();
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PreferencesHelper', `setString failed: ${err.code} ${err.message}`);
    }
  }

  static getLong(key: string, defaultValue: number): number {
    if (PreferencesHelper.store === null) {
      return defaultValue;
    }
    try {
      return PreferencesHelper.store.getSync(key, defaultValue) as number;
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PreferencesHelper', `getLong failed: ${err.code} ${err.message}`);
      return defaultValue;
    }
  }

  static setLong(key: string, value: number): void {
    if (PreferencesHelper.store === null) {
      return;
    }
    try {
      PreferencesHelper.store.putSync(key, value);
      PreferencesHelper.store.flush();
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PreferencesHelper', `setLong failed: ${err.code} ${err.message}`);
    }
  }

  static getStringArray(key: string, defaultValue: string[]): string[] {
    if (PreferencesHelper.store === null) {
      return defaultValue;
    }
    try {
      return PreferencesHelper.store.getSync(key, defaultValue) as string[];
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PreferencesHelper', `getStringArray failed: ${err.code} ${err.message}`);
      return defaultValue;
    }
  }

  static setStringArray(key: string, value: string[]): void {
    if (PreferencesHelper.store === null) {
      return;
    }
    try {
      PreferencesHelper.store.putSync(key, value);
      PreferencesHelper.store.flush();
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'PreferencesHelper', `setStringArray failed: ${err.code} ${err.message}`);
    }
  }
}
