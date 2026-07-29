import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { HistoryDB } from '../utils/HistoryDB';

export default class ShareAbility extends ShareExtensionAbility {
  onCreate(): void {
    PreferencesHelper.init(this.context);
    HistoryDB.init(this.context);
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        const records = data.getRecords();
        let sharedText = '';
        if (records.length > 0) {
          sharedText = records[0].content ?? '';
        }
        if (sharedText.length === 0) {
          sharedText = this.extractTextFromWant(want);
        }
        const storage: LocalStorage = new LocalStorage();
        storage.setOrCreate('shareText', sharedText);
        storage.setOrCreate('session', session);
        session.loadContent('pages/SharePanel', storage);
      })
      .catch((error: BusinessError) => {
        const sharedText = this.extractTextFromWant(want);
        const storage: LocalStorage = new LocalStorage();
        storage.setOrCreate('shareText', sharedText);
        storage.setOrCreate('session', session);
        session.loadContent('pages/SharePanel', storage);
      });
  }

  private extractTextFromWant(want: Want): string {
    if (want.parameters !== undefined && want.parameters !== null) {
      const params = want.parameters as Record<string, string>;
      const text = params['text'] ?? params['android.intent.extra.TEXT'] ?? '';
      if (text.length > 0) {
        return text;
      }
    }
    if (want.uri !== undefined && want.uri !== null) {
      return want.uri;
    }
    return '';
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
  }

  onDestroy(): void {
  }
}
