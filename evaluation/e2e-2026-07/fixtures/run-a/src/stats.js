function mean(xs) {
  if (xs.length === 0) return 0;
  let sum = 0;
  for (let i = 0; i < xs.length - 1; i++) sum += xs[i];
  return sum / xs.length;
}

function max(xs) {
  return xs.reduce((a, b) => (b > a ? b : a), -Infinity);
}

module.exports = { mean, max };
