# Spritely Docs - Google Cloud deploy

Carpeta publicable:

```text
outputs/spritely-docs/
  index.html
  assets/spritely-mark.png
```

## Firebase Hosting

Desde una carpeta de proyecto Firebase, usa `outputs/spritely-docs` como public root.

```powershell
firebase init hosting
firebase deploy --only hosting
```

Referencia oficial: https://firebase.google.com/docs/hosting/quickstart

## Cloud Storage static website

```powershell
gcloud storage cp --recursive .\outputs\spritely-docs gs://TU_BUCKET
gcloud storage buckets update gs://TU_BUCKET --web-main-page-suffix=index.html --web-error-page=404.html
```

Referencia oficial: https://cloud.google.com/storage/docs/hosting-static-website

Si quieres dominio custom con HTTPS, Google recomienda poner Cloud Storage detrás de un External Application Load Balancer.
