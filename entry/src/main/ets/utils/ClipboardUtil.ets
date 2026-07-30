import { pasteboard } from '@kit.BasicServicesKit';

export function copyToClipboard(uiContext: UIContext, text: string): void {
  try {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(pasteData);
    uiContext.getPromptAction().showToast({ message: $r('app.string.copied') });
  } catch (e) {
    try {
      uiContext.getPromptAction().showToast({ message: $r('app.string.copy_failed') });
    } catch (err) {
      console.info(`showToast failed: ${err}`);
    }
  }
}
