importScripts("https://www.gstatic.com/firebasejs/9.1.3/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.1.3/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyATn3jT3jAIF78CaJiXgCZbW-zDVkMhC68",
  projectId: "afyalink-app-cba6f",
  messagingSenderId: "697790023667",
  appId: "1:697790023667:web:7f6f1a8c0d1e3a5b2c4d6e",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
