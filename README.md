# Easy to use Firebase Emulator setup

Project provides Docker container to run Firebase Emulator locally.

Currently supported features:
* Firebase Auth
* Firebase Database

Feel free to open PR to enable other Firebase features.

# Usage

## Build Docker container

```bash
docker build -t firebase-emulator .
```

## Run

```bash
docker run -p 9099:9099 -p 4000:4000 firebase-emulator
```

By default it will:
* run Firebase Auth Emulator at http://localhost:9099/,
* run Emulator UI at http://localhost:4000/,
* use `demo-project` as project ID.

# Configuration

Configuration is done via the following env variables:
* `FIREBASE_PORT_DATABASE` (default: 9000)
* `FIREBASE_PORT_AUTH` (default: 9099)
* `FIREBASE_PORT_UI` (default: 4000)
* `FIREBASE_PROJECT` (default: `demo-project`)

# Client side

## Javascript

### Server

1. Make sure that you use recent `firebase-admin` (at last `> 9.5.0`),
2. Specify `FIREBASE_AUTH_EMULATOR_HOST` env var as `<host>:<port>` without (!) protocol prefix,
3. Specify `demo-project` as project ID:
   ```javascript
   import admin from "firebase-admin"

   admin.initializeApp({ projectId: "demo-project" })
   ```

### Client

1. Specify `FIREBASE_AUTH_EMULATOR_HOST` as `http://<host>:<port>` with (!) protocol prefix

# Firebase Database (optional)

## Init Firebase project

If you have existing firebase project, you may want to import rules & dataset
first.

To do so, you need to have [firebase tool][1] to be installed.

First, create some new directory to host your Firebase data and `cd` into it.

Then, init project by using your existing remote Firebase project:

```bash
firebase list
firebase --project <project-id> init database
```

After this step you should have two files in your directory:

* `firebase.json`
* `database.rules.json`

**NOTE**: if you do not care about actual rules, you can just create empty
`firebase.json` by yourself:

```bash
echo '{}' > firebase.json
```

Then, you need to export your dataset:

```bash
firebase --project <project-id> database:get / > database.json
```

## Start Docker container

You need to run this command from same directory as in previous step:

```bash
docker run -d -v `pwd`:/firebase -p 9000:9000 -p 9099:9099 -p 4000:4000 firebase-emulator
```

[1]: https://github.com/firebase/firebase-tools
