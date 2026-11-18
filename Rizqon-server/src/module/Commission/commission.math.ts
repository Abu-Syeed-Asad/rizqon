import { Prisma } from "../../../prisma/generated/prisma/client.js";
import { fail } from "./commission.common.js";

// Isolated precision avoids changing Prisma's global Decimal configuration.
type DecimalValue = string | number | Prisma.Decimal;
const Decimal = Prisma.Decimal.clone({ precision: 48, rounding: Prisma.Decimal.ROUND_HALF_UP });
export const decimal = (value: DecimalValue) => new Decimal(value);
export const sum = (values: DecimalValue[]) => values.reduce<Prisma.Decimal>((total, value) => total.plus(value), decimal(0));
export function money(value: DecimalValue) {
  const result = decimal(value).toDecimalPlaces(2, Prisma.Decimal.ROUND_HALF_UP);
  if (!result.isFinite() || result.abs().gt("9999999999999999.99")) fail("Money exceeds supported precision", 400);
  return result;
}

export function calculateCommission(unitPrice: DecimalValue, quantity: DecimalValue,
  discount: DecimalValue, percent: DecimalValue) {
  const price = decimal(unitPrice), qty = decimal(quantity), rate = decimal(percent), reduction = decimal(discount);
  if (![price, qty, rate, reduction].every(v => v.isFinite()) || price.lt(0) || qty.lte(0) || reduction.lt(0)
    || rate.lt(0) || rate.gt(100)) fail("Invalid commission calculation inputs", 400);
  const grossBase = money(price.mul(qty).minus(reduction));
  if (grossBase.lt(0)) fail("Discount exceeds sale item value", 400);
  const commissionAmount = money(grossBase.mul(rate).div(100));
  return { grossBase, commissionPercent: rate, commissionAmount, partnerPayable: grossBase.minus(commissionAmount) };
}

export function cumulativeAllocation(original: { grossBase: DecimalValue; commissionAmount: DecimalValue },
  sold: DecimalValue, returned: DecimalValue) {
  const grossBase = money(decimal(original.grossBase).mul(returned).div(sold));
  // Allocate commission from the rounded base so a tiny partial return can never have
  // a commission larger than its base (which would produce a positive return payable).
  const commissionAmount = decimal(original.grossBase).eq(0) ? decimal(0)
    : money(decimal(original.commissionAmount).mul(grossBase).div(original.grossBase));
  return { grossBase, commissionAmount, partnerPayable: grossBase.minus(commissionAmount) };
}

// Difference of cumulative rounded totals assigns the residual cent to the final return.
export function calculateReversal(original: { grossBase: DecimalValue; commissionAmount: DecimalValue },
  sold: DecimalValue, returnedBefore: DecimalValue, returning: DecimalValue) {
  const quantity = decimal(sold), prior = decimal(returnedBefore), current = decimal(returning), cumulative = prior.plus(current);
  if (![quantity, prior, current].every(v => v.isFinite()) || quantity.lte(0) || prior.lt(0) || current.lte(0) || cumulative.gt(quantity)) fail("Return quantity exceeds the original sale", 400);
  const before = cumulativeAllocation(original, quantity, prior), after = cumulativeAllocation(original, quantity, cumulative);
  const grossBase = after.grossBase.minus(before.grossBase).negated();
  const commissionAmount = after.commissionAmount.minus(before.commissionAmount).negated();
  return { grossBase, commissionAmount, partnerPayable: grossBase.minus(commissionAmount) };
}
