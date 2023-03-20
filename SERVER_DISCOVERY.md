# Server Discovery

**NOTE**: the format of `v2` is stable as of 2020-08-26. Format changes will
only occur in a different directory, e.g. `v3` if necessary in the future.

This document describes how eduVPN applications find out about eduVPN servers.

Two JSON documents are available to facilitate eduVPN server discovery:
 
- Server List: `https://disco.eduvpn.org/v2/server_list.json`
- Organization List: `https://disco.eduvpn.org/v2/organization_list.json`

The application MUST keep working when the discovery file(s) can not be 
downloaded and/or verified for whatever reason, including, but not limit to 
DNS does not resolve, traffic to the discovery server is blocked, server 
returns unexpected error code. In this case an user dismissable error MUST be 
shown, but it MUST NOT block the application from working with the old data 
already available to the app. Application releases SHOULD include the latest 
version from the discovery server before publishing the binary, if practical. 
This in case the discovery server is down on the application's first launch.

## Server List

The "Server List" contains a list of _all_ eduVPN servers. In this list we 
distinguish between two _types_ of servers (`server_type`):

- Secure Internet: in case a user has access to _any_ one of the 
  "Secure Internet" servers, the user can use _all_ of them;
- Institute Access: for exclusive use by users belonging to the organization 
  running the service and that can log in to this service.

The "Secure Internet" servers are named after the country they are in, e.g. 
"The Netherlands". The "Institute Access" servers are named after the institute
they belong to, e.g. "Utrecht School of the Arts".

    {
      "server_list": [
        {
            "server_type": "institute_access",
            "base_url": "https://hku.eduvpn.nl/",
            "display_name": {
                "en-US": "Utrecht School of the Arts",
                "nl-NL": "Hogeschool voor de Kunsten Utrecht"
            },
            "keyword_list": "hku"
        },
        {
            "server_type": "secure_internet",
            "base_url": "https://eduvpn.rash.al/",
            "country_code": "AL",
            "support_contact": [
                "mailto:helpdesk@rash.al"
            ]
        },
        
        ...

        ...
            
      ]
    }

The application MUST always fetch the `server_list.json` at application start. 
The application MAY refresh the `server_list.json` periodically, e.g. once 
every hour. The reason for this is that the list of servers changes regularly.

The keys `server_type`, `base_url` are required for all server types. The 
`display_name` key is required for the `institute_access` server type. The 
`country_code` key is required for the `secure_internet` server type.

## Organization List

The "Organization List" contains a list of all known organizations and their
mapping to the "Secure Internet" servers. In order to be able to use all 
"Secure Internet" servers, the user needs to know _which_ of the 
"Secure Internet" servers they have access to based on their 
"Home Organization". The "Organization List" contains a mapping between 
organization and "Secure Internet" server through the `secure_internet_home` 
key that points to a `base_url` of a server entry in the "Server List" of the
key `server_type` with value `secure_internet`:

    {
      "organization_list": [
        {
          "display_name": {
            "nl": "SURFnet bv",
            "en": "SURFnet bv"
          },
          "org_id": "https://idp.surfnet.nl",
          "secure_internet_home": "https://nl.eduvpn.org/",
          "keyword_list": {
            "en": "SURFnet bv SURF konijn surf surfnet powered by",
            "nl": "SURFnet bv SURF konijn powered by"
          }
        },

        ...

        ... 

      ]
    }

The application MUST only download the `organization_list.json` when it is 
needed. It is only needed:

- on "first launch" when offering the search for "Institute Access" and 
  "Organizations";
- when the user tries to add new server AND the user did NOT yet choose an 
  organization before;
- when the authorization for the server associated with an already chosen 
  organization is triggered, e.g. after expiry or revocation.

The reason for this is that the list can get quit big. We expect it can be up
to 1MB in the future.

The keys `display_name`, `org_id`, `secure_internet_home` are required keys. 
The `keyword_list` is optional.

**NOTE**: when the `org_id` that the user chose previously is no longer 
available in `organization_list.json` the application should ask the user to 
choose their organization (again). This can occur for example when the 
organization replaced their identity provider,  uses a different domain after 
rebranding or simply ceased to exist.

## Support Contact

The OPTIONAL key `support_contact` contains a list of possible contact options 
to be displayed in the application.

- `mailto:X`
- `https://X`
- `tel:X`

## Keywords

The OPTIONAL key `keyword_list` contains a string, or object containing 
keywords, example:

    "keyword_list": {
      "en": "SURFnet bv SURF konijn surf surfnet powered by",
      "nl": "SURFnet bv SURF konijn powered by"
    }

**NOTE**: the `keyword_list` MUST be supported in both `organization_list.json` 
and `server_list.json`.

## Language Matching

We assume the OS the user is using has some kind of locale set up. For example
the OS is set to `en-US`, `nl-NL` or `de-DE`. 

The field `keyword_list` (and `display_name` for the organization list and 
server list for server type `institute_access`) are either of type `string` or 
of type `object`. If they are of type `string` the value is used/displayed 
as-is. If they are of type `object` a match is made to pick the "best" 
translation based on the OS language setting.

We use the 
[IETF BCP 47 language tag](https://en.wikipedia.org/wiki/IETF_language_tag). A 
comprehensive "mapping" rules are discussed in 
[section 4](https://tools.ietf.org/html/rfc5646#section-4) of RFC 5646. If your
OS or the standard library of the OS provides support for this use it. If not,
you can implement a subset of this matching yourself.

Start from the OS language setting, e.g. `de-DE`.

1. Try to find the exact match, so search for `de-DE` in this case;
2. Try to find a key that *starts* with the OS language setting, e.g. 
`de-DE-x-foo`;
3. Try to find a key that *starts* with the first part of the OS language, e.g. 
`de-`, if not available search for just the language, e.g. `de`;
4. Pick one that is deemed best, e.g. `en-US` or `en`, but note that not all 
languages are always available!

### Search

When searching for organizations (and servers) the device locale should not be
used to restrict searches to that particular locale, but search in all locales.

The search takes place in both `display_name` and `keyword_list`.

## Country Code

The "Secure Internet" servers from `server_list.json` have a `country_code` 
field. This field MUST be used to find an appropriate translation of the 
country name and flag for display in the UI. If the OS you are writing an 
application for allows you to "internationalize" country codes (or country 
names) this SHOULD be used.

If such functionality is lacking you can use the file 
[here](https://github.com/eduvpn/artwork/blob/master/country_code_to_country_mapping.json).

You can find many country flags for use by your application 
[here](https://github.com/eduvpn/artwork/tree/master/App/Flags). Copy those in
your assets folder, do not fetch them dynamically!

**NOTE**: if you use these assets, they MUST be included in your application. 
It MUST NOT be fetched at application run time! There is no guarantee these
files will remain available at this exact location!

## Signatures

All JSON discovery files have a signature. The signatures are generated with 
[minisign](https://jedisct1.github.io/minisign/):

- Server List: `https://disco.eduvpn.org/v2/server_list.json.minisig`
- Organization List: `https://disco.eduvpn.org/v2/organization_list.json.minisig`

The minisign documentation shows the format of the signatures and public keys.

As of 2020-09-18 the public keys that are to be trusted for signing the 
discovery files are:

| Owner                | Public Key                                                 |
| -------------------- | ---------------------------------------------------------- |
| `fkooman@deic.dk`, `kolla@uninett.no ` | `RWRtBSX1alxyGX+Xn3LuZnWUT0w//B6EmTJvgaAxBMYzlQeI+jdrO6KF` |
| ~~`jornane@uninett.no`~~ | ~~`RWQ68Y5/b8DED0TJ41B1LE7yAvkmavZWjDwCBUuC+Z2pP9HaSawzpEDA`~~ |
| RoSp                 | `RWQKqtqvd0R7rUDp0rWzbtYPA3towPWcLDCl7eY9pBMMI/ohCmrS0WiM` |

**NOTE**: you MUST allow your application to contain _multiple_ public keys for 
verification. A signature is considered valid if it is correctly signed by one
of the public keys. So your verification algorithm MUST perform proper
signature's public key identification, matching against the list of trusted
public keys and finally validating content integrity. Any error in the process
MUST be shown to the user of the application. Failing to update the discovery
files results in the old one remaining valid.

**NOTE**: versions of minisign >= 0.10 default to using 
[prehashed](https://jedisct1.github.io/minisign/#signature-format) signatures 
instead of "legacy" signatures. Make sure your application supports both legacy 
and prehashed signatures and contains a toggle to be flipped in the future to 
enforce only prehashed signatures, similar to the `-H` option in 
minisign >= 0.10.

### Rollback Prevention

The JSON files contain a `v` key to contains the 
[Unix time](https://en.wikipedia.org/wiki/Unix_time). The field MUST be used to
prevent "rollback" to older versions.

When downloading a new version, it MUST be ensured that the `v` field of the
new file is `>` the `v` field of the old version. As an example:

    {
      "v": 1594022992,
      "server_list": [
        {
            // ...
        }
      ]
    }

In case the newly retrieved file contains a `v` that is _lower_ than the one 
the application currently has it MUST NOT be used. If the `v` is identical, the
file can be considered unchanged and the old version MUST be used.

The user SHOULD be notified if the server contains an older version of the file
the app currently has, but the user MUST be allowed to continue, where the app
will use the copy of the file it already had.

## Authorization

See [API](API.md) for the actual OAuth flow. For "Secure Internet" servers you
also MUST implement 
[SERVER_DISCOVERY_SKIP_WAYF](SERVER_DISCOVERY_SKIP_WAYF.md).
