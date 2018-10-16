"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const realm_object_server_1 = require("realm-object-server");
const path = require("path");
const server = new realm_object_server_1.BasicServer();
server.start({
    dataPath: path.join(__dirname, '../data'),
    logger: new realm_object_server_1.FileConsoleLogger(path.join(__dirname, '../log.txt'), 'all', {
        file: {
            timestamp: true,
            level: 'debug'
        },
        console: {
            level: 'info'
        }
    }),
    featureToken: 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJOb3RpZmllciI6dHJ1ZSwiU3luYyI6dHJ1ZSwiTG9hZEJhbGFuY2luZyI6dHJ1ZSwiQWRhcHRlciI6dHJ1ZSwiQmFja3VwIjp0cnVlLCJDbGllbnRFbWFpbCI6InNpcmFya2ltZWRlc0BnbWFpbC5jb20iLCJpYXQiOjE1MzQ5ODI4MjAsImV4cCI6MTUzNzU3NDgyMH0.NrNuAAPjKFIEAbVXbJysgguLZZej2xZBwZrCH_C8IDHrT-KsoNlKxfXS5_RucVtlKPbv91tFQpAHtIt3Yf4_dydQ5D0xBxSPzO4zfXiX5tUa-3-BRc2wFKHkb6WP8gKjR3KmRAQVGlgYczQSOzZz_-adaFraDAXp2xpmtndHYsBpnaGDIvpBe04v9jv-BkC1SPDqiKcRZokZ8O-QZMnGVUCfBTINLoJPPdPXf34JegUx4cteYuXXK85vrebyuxYbqBz67SSmzGx76EBqnMBwkdFtlsUWj4QVTgKF_At5Y3LuRZzDDcuCFV47ujd1gsD_xmGr934h-HPVK-mte30z2Q',
})
    .then(() => {
    console.log(`Realm Object Server was started on ${server.address}`);
})
    .catch(err => {
    console.error(`Error starting Realm Object Server: ${err.message}`);
});
//# sourceMappingURL=index.js.map