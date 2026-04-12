import { defineAuth } from "@aws-amplify/backend";

export const auth = defineAuth({
  loginWith: {
    email: true,
  },
  groups: ["sub-contractor", "main-contractor", "qs", "admin"],
});
