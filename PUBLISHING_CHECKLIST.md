# Publishing Checklist

- Choose and add a project license.
- Review all `files/etc/config/*` values for site/customer-specific addresses, SSIDs, routes, and identifiers.
- Replace every `CHANGE_ME_*` value before deploying a built image.
- Confirm no `/etc/shadow`, password hashes, Dropbear host private keys, or backup archives are staged.
- Confirm no generated firmware images are staged; publish them through GitHub Releases instead.
- Review documentation screenshots for sensitive/customer information before making the repository public.
- Run a secret scanner such as `gitleaks` or GitHub secret scanning before publication.
