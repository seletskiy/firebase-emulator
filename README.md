# Local Firebase Instance

Project provides Docker container to run Firebase Emulator locally.

# Usage

## Build Docker container

```bash
docker build -t firebase-emulator .
```

## Init Firebase project

If you have existing firebase project, you may want to import rules & dataset
first.

To do so, you need to have [firebase tool][1] to be installed.

First, create some new directory to host your Firebase data and `cd` into it.

Then, init project by using your existing remote Firebase project (choose
only `Database` in interactive prompt):

```bash
firebase list
firebase --project <project-id> init
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
docker run -d -v `pwd`:/firebase -p 443:443 firebase-emulator
```

## Add self-signed `nginx.crt` to your local trust store

After container was started, `nginx.crt` file should appear in your Firebase
directory.

In order to access Firebase container by HTTPS, you need to add generated
certificate into your local trust store:

```bash
sudo trust anchor nginx.crt
```

## Add `local.firebaseio.com` to hosts

```bash
sudo tee -a /etc/hosts <<< '127.0.0.1 local.firebaseio.com'
```

## Try

```bash
curl -s https://local.firebaseio.com/.json
```

[1]: https://github.com/firebase/firebase-tools
