import { pasteboard } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export function copyToClipboard(uiContext: UIContext, text: string): void {
  try {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(pasteData);
    uiContext.getPromptAction().showToast({ message: $r('app.string.copied') });
  } catch (e) {
    hilog.error(0x0000, 'ClipboardUtil', `copyToClipboard failed: ${e}`);
    try {
      uiContext.getPromptAction().showToast({ message: $r('app.string.copy_failed') });
    } catch (toastErr) {
      hilog.error(0x0000, 'ClipboardUtil', `showToast failed: ${toastErr}`);
    }
  }
}
