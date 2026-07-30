import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { HistoryDB } from '../utils/HistoryDB';
import { detectBarcode, scanBarcode, scanCore } from '@kit.ScanKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class ShareAbility extends ShareExtensionAbility {
  onCreate(): void {
    PreferencesHelper.init(this.context);
    HistoryDB.init(this.context);
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    systemShare.getSharedData(want)
      .then(async (data: systemShare.SharedData) => {
        const records = data.getRecords();
        let sharedText = '';
        let imageUri = '';

        if (records.length > 0) {
          const record = records[0];
          if (record.utd !== undefined) {
            try {
              const descriptor = utd.getTypeDescriptor(record.utd);
              if (descriptor !== null && descriptor.belongsTo(utd.UniformDataType.IMAGE)) {
                imageUri = record.uri ?? '';
              } else {
                sharedText = record.content ?? '';
              }
            } catch (e) {
              const err = e as BusinessError;
              hilog.error(0x0000, 'ShareAbility', `getTypeDescriptor failed: ${err.code} ${err.message}`);
              sharedText = record.content ?? '';
            }
          } else {
            sharedText = record.content ?? '';
          }
        }

        if (imageUri.length === 0 && want.uri !== undefined && want.uri !== null && want.uri.length > 0) {
          imageUri = want.uri;
        }

        if (imageUri.length > 0) {
          sharedText = await this.decodeImageBarcode(imageUri);
        }

        this.loadSharePanel(session, sharedText);
      })
      .catch((error: BusinessError) => {
        const sharedText = this.extractTextFromWant(want);
        this.loadSharePanel(session, sharedText);
      });
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
  }

  onDestroy(): void {
  }

  private async decodeImageBarcode(imageUri: string): Promise<string> {
    try {
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: true,
        enableAlbum: true,
      };
      const inputImage: detectBarcode.InputImage = { uri: imageUri };
      const results = await detectBarcode.decode(inputImage, options);
      if (results.length > 0) {
        return results[0].originalValue;
      }
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'ShareAbility', `decodeImageBarcode failed: ${err.code} ${err.message}`);
    }
    return '';
  }

  private loadSharePanel(session: UIExtensionContentSession, shareText: string): void {
    AppStorage.setOrCreate('shareText', shareText);
    AppStorage.setOrCreate('session', session);
    try {
      session.loadContent('pages/SharePanel');
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(0x0000, 'ShareAbility', `loadContent failed: ${err.code} ${err.message}`);
    }
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
}
