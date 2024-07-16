import bcrypt from 'bcryptjs'

// context(peterp, 16th May 2023): Yes. I'm using a static SALT value instead of a dynamic one per password.
// That's because the CLI does not send the userId along with the authorization header,
// so I cannot compare the hash associated to the user in the database
// with the cleartext password.
//
// We can resolve this, but I need to invalidate every token, and that's going to require a bit of
// external communcation.

const SALT = '$2b$10$imwkqhwFtzPmD67TePkJXu'

export const hashPassword = async (password: string) => {
  return await bcrypt.hash(password, SALT)
}
