import { hapTasks } from '@ohos/hvigor-ohos-plugin';
import { ossScanPlugin } from 'osslibraries-hvigor-plugin';

export default {
  system: hapTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: [ossScanPlugin({includeOhpmCache: true})] /* Custom plugin to extend the functionality of Hvigor. */
}