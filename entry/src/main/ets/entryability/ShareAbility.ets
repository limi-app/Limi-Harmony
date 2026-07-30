import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { HistoryDB } from '../utils/HistoryDB';
import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'ShareAbility';

export default class ShareAbility extends ShareExtensionAbility {
  onCreate(): void {
    PreferencesHelper.init(this.context);
    HistoryDB.init(this.context);
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    hilog.info(DOMAIN, TAG, `onSessionCreate want: uri=${want.uri ?? 'null'}, action=${want.action ?? 'null'}`);
    systemShare.getSharedData(want)
      .then(async (data: systemShare.SharedData) => {
        const records = data.getRecords();
        hilog.info(DOMAIN, TAG, `getSharedData records count: ${records.length}`);
        let sharedText = '';
        let imageUri = '';

        if (records.length > 0) {
          const record = records[0];
          hilog.info(DOMAIN, TAG, `record utd=${record.utd ?? 'undefined'}, content=${record.content ?? 'null'}, uri=${record.uri ?? 'null'}`);
          if (record.utd !== undefined) {
            try {
              const descriptor = utd.getTypeDescriptor(record.utd);
              if (descriptor !== null && descriptor.belongsTo(utd.UniformDataType.IMAGE)) {
                imageUri = record.uri ?? '';
              } else {
                sharedText = record.content ?? '';
              }
            } catch (e) {
              sharedText = record.content ?? '';
            }
          } else {
            sharedText = record.content ?? '';
          }
        }

        if (imageUri.length === 0 && want.uri !== undefined && want.uri !== null && want.uri.length > 0) {
          imageUri = want.uri;
          hilog.info(DOMAIN, TAG, `using want.uri as image: ${imageUri}`);
        }

        if (imageUri.length > 0) {
          hilog.info(DOMAIN, TAG, `decoding barcode from image: ${imageUri}`);
          sharedText = await this.decodeImageBarcode(imageUri);
          hilog.info(DOMAIN, TAG, `decode result: ${sharedText.length > 0 ? sharedText : '(empty)'}`);
        }

        if (sharedText.length === 0) {
          sharedText = '';
        }

        this.loadSharePanel(session, sharedText);
      })
      .catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, `getSharedData failed: ${error.code} ${error.message}`);
        const sharedText = this.extractTextFromWant(want);
        this.loadSharePanel(session, sharedText);
      });
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
      hilog.error(DOMAIN, TAG, `detectBarcode failed: ${err.code} ${err.message}`);
    }
    return '';
  }

  private loadSharePanel(session: UIExtensionContentSession, shareText: string): void {
    const storage: LocalStorage = new LocalStorage();
    storage.setOrCreate('shareText', shareText);
    storage.setOrCreate('session', session);
    session.loadContent('pages/SharePanel', storage);
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
