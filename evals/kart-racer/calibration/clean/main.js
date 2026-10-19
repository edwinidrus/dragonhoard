const c = document.getElementById('game'); const g = c.getContext('2d');
let x = 20, frames = 0;
addEventListener('keydown', e => { if (e.key === 'ArrowUp') x += 10; });
function tick() {
  frames++;
  g.clearRect(0, 0, c.width, c.height); g.fillRect(x, 50, 20, 20);
  document.title = `frames=${frames} x=${x}`;
  requestAnimationFrame(tick);
}
console.log('hoard-probe ready');
requestAnimationFrame(tick);
