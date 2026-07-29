import { processLinksInText } from '../logic/Rule';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { hdsMaterial, HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { ProcessPanel } from '../components/ProcessPanel';
import { buildTitleBarOpts, getMaterialLevel } from '../components/TitleBarBuilder';
import { copyToClipboard } from '../utils/ClipboardUtil';
import { saveHistoryIfEnabled } from '../utils/HistoryUtil';

@Entry
@ComponentV2
struct SharePanelPage {
  @Local originalText: string = '';
  @Local processedText: string = '';
  @Local processedUrlList: string[] = [];
  @Local isProcessing: boolean = false;
  @Local isEditing: boolean = true;
  @Local editText: string = '';
  @Local isEmpty: boolean = false;
  @Local isNotHasUrls: boolean = false;
  @Local isError: boolean = false;
  @Local customMaterialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;
  private storage: LocalStorage = LocalStorage.getShared();
  private session: UIExtensionContentSession | null = null;

  aboutToAppear(): void {
    const shareText = this.storage.get<string>('shareText') ?? '';
    const sessionObj = this.storage.get<UIExtensionContentSession>('session');
    if (sessionObj !== undefined && sessionObj !== null) {
      this.session = sessionObj;
    }
    if (shareText.length > 0) {
      this.originalText = shareText;
      this.editText = shareText;
      this.isEditing = false;
      this.processText(shareText);
    }
    this.customMaterialLevel = getMaterialLevel();
  }

  async processText(text: string): Promise<void> {
    this.isProcessing = true;
    this.isEmpty = false;
    this.isError = false;
    this.isNotHasUrls = false;

    try {
      const result = await processLinksInText(text);
      this.processedText = result.processedText;
      this.processedUrlList = result.processedUrlList;
      this.isEmpty = result.isEmpty;
      this.isNotHasUrls = result.isNotHasUrls;

      if (!result.isEmpty && !result.isNotHasUrls) {
        await saveHistoryIfEnabled(this.originalText, this.processedText);
      }
    } catch (e) {
      this.processedText = `${e}`;
      this.isError = true;
    } finally {
      this.isProcessing = false;
    }
  }

  closeSession(): void {
    if (this.session !== null) {
      this.session.terminateSelf();
    }
  }

  build() {
    HdsNavigation() {
      Column() {
        ProcessPanel({
          isEditing: this.isEditing,
          onIsEditingChange: (v: boolean) => { this.isEditing = v; },
          editText: this.editText,
          onEditTextChange: (v: string) => { this.editText = v; },
          originalText: this.originalText,
          onOriginalTextChange: (v: string) => { this.originalText = v; },
          processedText: this.processedText,
          processedUrlList: this.processedUrlList,
          isProcessing: this.isProcessing,
          isEmpty: this.isEmpty,
          isNotHasUrls: this.isNotHasUrls,
          isError: this.isError,
          showShareButton: false,
          onConfirm: (text: string) => {
            this.processText(text);
          },
          onCopy: (text: string) => {
            copyToClipboard(this.getUIContext(), text);
          },
        })
      }.width('100%').padding({ left: 16, right: 16, bottom: 8 })
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .titleMode(HdsNavigationTitleMode.MINI)
    .titleBar(buildTitleBarOpts('Limi', this.customMaterialLevel, {
      backIcon: {
        action: (): void => {
          this.closeSession();
        }
      }
    }))
    .padding({ top: 6 })
  }
}
