import { app } from '@ohos/hvigor-ohos-plugin';
app({
  root: {
    buildMode: [{ name: 'debug' }, { name: 'release' }],
  },
});
