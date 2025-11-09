/*
  機能: PWA Service Worker

  用途:
  - Web Push通知の処理（現在はコメントアウト）
  - 通知クリック時の動作制御

  実装可能な機能:
  - push: プッシュ通知受信時の処理
  - notificationclick: 通知クリック時にアプリを開く

  注意: 現在は実装例としてコメントアウトされています
*/

// Add a service worker for processing Web Push notifications:
//
// self.addEventListener("push", async (event) => {
//   const { title, options } = await event.data.json()
//   event.waitUntil(self.registration.showNotification(title, options))
// })
//
// self.addEventListener("notificationclick", function(event) {
//   event.notification.close()
//   event.waitUntil(
//     clients.matchAll({ type: "window" }).then((clientList) => {
//       for (let i = 0; i < clientList.length; i++) {
//         let client = clientList[i]
//         let clientPath = (new URL(client.url)).pathname
//
//         if (clientPath == event.notification.data.path && "focus" in client) {
//           return client.focus()
//         }
//       }
//
//       if (clients.openWindow) {
//         return clients.openWindow(event.notification.data.path)
//       }
//     })
//   )
// })
