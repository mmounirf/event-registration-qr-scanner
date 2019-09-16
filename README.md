# Event Registration QR Scanner

This Flutter app is created as a tool to help a friend of mine register guests at some event with the exact time they arrived. Basically, the app reads the QR code, check the if the value exists in Cloud Firestore database, and then update the record with the current timestamp. The app is used with a dashboard that you can find it [here](https://github.com/mmounirf/event-registration-dashboard)

If you want to use it please feel free to modify and use for your own event, same goes for the dashboard, you will need to provide your own `google-services.json` file. Follow the following [instructions](https://firebase.google.com/docs/flutter/setup) to setup the project with your Firebase configurations.

    

> This is my very first Flutter app., and to be honest nothing fancy in there. If you saw something that can be done in a better way, it's highly appreciated if you can reach out to me or drop me a line so I can get a better understanding about this awesome technology.
