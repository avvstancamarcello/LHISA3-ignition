// formatToken.js
export function formatToken(amountBigInt, decimals = 18, precision = 6) {
  try {
    const n = BigInt(amountBigInt ?? 0);
    const factor = 10n ** BigInt(decimals);
    const whole = n / factor;
    const frac = n % factor;
    const s = frac.toString().padStart(decimals, '0').slice(0, precision);
    return `${whole.toString()}.${s}`;
  } catch (e) {
    return '0.0';
  }
}
