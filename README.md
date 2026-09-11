# pk-random
Bash Script to pick out a Random Headmate from your PluralKit.\
NOTE: The Script explicitly filters by publicly visbile headmates.
This lets you set any "meme" proxies to private so they don't pop up in this.
(Yes.... we have a few meme proxies lmao)

# Dependencies
- A PluralKit Token
- `bash`
- `curl`
- `jq`
- `date`
- `awk`

# License
Copyright (C) 2026 GroboChan

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Running the program
```
git clone https://github.com/grobo-chan/pk-random
cd pk-random
bash ./script.sh [-b|--bias] [-t|--token TOKEN]
```

In --bias mode the headmate's who front less are more likely to be picked.\
This program will require your PK Token. These are used to send requests to the PK API to fetch members and front history.\
The token is NOT being sent anywhere else and is only used for the purpose of data fetching.\
If token is not supplied via --token, the program will ask for one.
