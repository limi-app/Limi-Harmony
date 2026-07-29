import { pasteboard } from '@kit.BasicServicesKit';

export function copyToClipboard(uiContext: UIContext, text: string): void {
  try {
    const pasteData = pasteboard.createPlainTextData(text);
    pasteboard.getSystemPasteboard().setData(pasteData);
    uiContext.getPromptAction().showToast({ message: $r('app.string.copied') });
  } catch (e) {
    uiContext.getPromptAction().showToast({ message: $r('app.string.copy_failed') });
  }
}
