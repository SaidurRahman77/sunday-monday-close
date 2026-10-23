const {onDocumentCreated} =
  require("firebase-functions/v2/firestore");

const {setGlobalOptions} =
  require("firebase-functions");

const {initializeApp} =
  require("firebase-admin/app");

const {getFirestore} =
  require("firebase-admin/firestore");

const {getMessaging} =
  require("firebase-admin/messaging");

const logger =
  require("firebase-functions/logger");

setGlobalOptions({
  maxInstances: 10,
});

initializeApp();

exports.sendPushNotification =
  onDocumentCreated(
      "notifications/{notificationId}",
      async (event) => {
        const snapshot = event.data;

        if (!snapshot) {
          logger.warn(
              "Notification snapshot missing.",
          );
          return;
        }

        const notification =
        snapshot.data();

        if (!notification) {
          logger.warn(
              "Notification data missing.",
          );
          return;
        }

        const recipientId =
        notification.recipientId;

        const title =
        notification.title ||
        "Sunday Monday Close";

        const message =
        notification.message || "";

        if (!recipientId) {
          logger.warn(
              "Notification has no recipientId.",
          );
          return;
        }

        const db =
        getFirestore();

        const devicesSnapshot =
        await db
            .collection("users")
            .doc(recipientId)
            .collection("devices")
            .get();

        if (devicesSnapshot.empty) {
          logger.info(
              `No devices found for ${recipientId}.`,
          );
          return;
        }

        const deviceMap =
        new Map();

        for (const deviceDoc
          of devicesSnapshot.docs) {
          const token =
          deviceDoc.data().token;

          if (
            typeof token === "string" &&
          token.trim().length > 0
          ) {
            deviceMap.set(
                token.trim(),
                deviceDoc.ref,
            );
          }
        }

        const tokens =
        Array.from(
            deviceMap.keys(),
        );

        if (tokens.length === 0) {
          logger.info(
              `No valid FCM tokens for ${recipientId}.`,
          );
          return;
        }

        const data = {
          notificationId:
          snapshot.id,

          type:
          String(
              notification.type || "",
          ),

          jobId:
          String(
              notification.jobId || "",
          ),

          applicationId:
          String(
              notification.applicationId ||
              "",
          ),

          title:
          String(title),

          message:
          String(message),
        };

        const response =
        await getMessaging()
            .sendEachForMulticast({
              tokens: tokens,

              notification: {
                title:
                String(title),

                body:
                String(message),
              },

              data: data,

              android: {
                priority:
                "high",

                notification: {
                  sound:
                  "default",
                },
              },
            });

        logger.info(
            "Push notification result.",
            {
              notificationId:
            snapshot.id,
              recipientId:
            recipientId,
              successCount:
            response.successCount,
              failureCount:
            response.failureCount,
            },
        );

        if (
          response.failureCount === 0
        ) {
          return;
        }

        const deletePromises = [];

        response.responses.forEach(
            (result, index) => {
              if (result.success) {
                return;
              }

              let errorCode = "";

              if (
                result.error &&
            result.error.code
              ) {
                errorCode =
              result.error.code;
              }

              logger.error(
                  "FCM send failed.",
                  {
                    errorCode:
                errorCode,
                    tokenIndex:
                index,
                  },
              );

              const invalidToken =
            errorCode ===
              "messaging/registration-token-not-registered" ||
            errorCode ===
              "messaging/invalid-registration-token";

              if (!invalidToken) {
                return;
              }

              const failedToken =
            tokens[index];

              const deviceRef =
            deviceMap.get(
                failedToken,
            );

              if (deviceRef) {
                deletePromises.push(
                    deviceRef.delete(),
                );
              }
            },
        );

        if (
          deletePromises.length > 0
        ) {
          await Promise.all(
              deletePromises,
          );

          logger.info(
              `${deletePromises.length} invalid device token(s) removed.`,
          );
        }
      },
  );
