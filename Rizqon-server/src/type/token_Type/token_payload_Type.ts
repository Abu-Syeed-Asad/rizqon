export interface ITokenPayload <T>  {
  name: string;
  email: string;
  id: string;
  data?:[T]
} 