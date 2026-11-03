import * as THREE from 'three';

export function createSky() {
  const group = new THREE.Group();
  const geometry = new THREE.SphereGeometry(450, 128, 96);
  const positions = geometry.getAttribute('position');
  const colors = new Float32Array(positions.count * 3);
  const stops = [[-90, 0xffc36b], [0, 0xffc36b], [6, 0xf08a5d],
    [15, 0xb45a8c], [30, 0x3a2463], [90, 0x1b1240]]
    .map(([angle, hex]) => [angle, new THREE.Color(hex)]);
  const blueGrey = new THREE.Color(0x586579);
  const rose = new THREE.Color(0xb45a8c);
  const day = new THREE.Color(0x8fc7e8);
  const color = new THREE.Color();
  const dome = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial({
    vertexColors: true, side: THREE.BackSide, depthWrite: false, fog: false,
  }));
  dome.renderOrder = -1000;
  group.add(dome);

  const sun = new THREE.Mesh(new THREE.CircleGeometry(4, 48),
    new THREE.MeshBasicMaterial({ color: 0xfff1c1, depthWrite: false, fog: false }));
  const elevation = THREE.MathUtils.degToRad(4.5);
  sun.position.set(440 * Math.cos(elevation), 440 * Math.sin(elevation), 0);
  sun.lookAt(0, 0, 0);
  sun.renderOrder = -999;
  group.add(sun);

  // ponytail: one deterministic points batch, square untextured stars; discs need a later choice.
  const stars = [];
  for (let i = 0; i < 180; i++) {
    const azimuth = i * 2.399963229728653;
    const y = THREE.MathUtils.lerp(Math.sin(Math.PI / 4 + 0.02), 0.999, (i + 0.5) / 180);
    const r = Math.sqrt(1 - y * y);
    stars.push(440 * r * Math.cos(azimuth), 440 * y, 440 * r * Math.sin(azimuth));
  }
  const starGeometry = new THREE.BufferGeometry();
  starGeometry.setAttribute('position', new THREE.Float32BufferAttribute(stars, 3));
  const points = new THREE.Points(starGeometry, new THREE.PointsMaterial({
    color: 0x777b9b, size: 1.3, sizeAttenuation: false, depthWrite: false, fog: false,
  }));
  points.renderOrder = -998;
  group.add(points);

  function setTrack(track) {
    const dusk = track.id === 'lantern';
    sun.visible = points.visible = dusk;
    for (let i = 0; i < positions.count; i++) {
      const y = Math.max(-1, Math.min(1, positions.getY(i) / 450));
      const angle = THREE.MathUtils.radToDeg(Math.asin(y));
      if (dusk) {
        const index = Math.min(stops.length - 2, stops.findIndex(([a]) => a >= angle) - 1);
        const low = Math.max(0, index);
        const [a, c] = stops[low];
        const [b, d] = stops[low + 1];
        color.copy(c).lerp(d, THREE.MathUtils.clamp((angle - a) / (b - a), 0, 1));
        const opposite = Math.max(0, -positions.getX(i) / 450) ** 2;
        color.lerp(blueGrey, opposite * Math.exp(-(((angle - 1) / 8) ** 2)));
        color.lerp(rose, opposite * 0.65 * Math.exp(-(((angle - 10) / 4) ** 2)));
      } else color.copy(day);
      color.toArray(colors, i * 3);
    }
    geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  }
  setTrack({ id: 'ember' });
  return { group, setTrack };
}
