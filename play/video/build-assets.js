// Packs fonts, the logo and the bits of real app data the film shows into
// assets.js as data URLs, so the page never touches file:// at runtime.
const fs = require('fs');
const path = require('path');

const ROOT = 'C:/Dev/hisn';
const b64 = (p) => fs.readFileSync(path.join(ROOT, p)).toString('base64');

const fonts = {
  'Readex|400': 'assets/fonts/ui/ReadexPro-Regular.ttf',
  'Readex|500': 'assets/fonts/ui/ReadexPro-Medium.ttf',
  'Readex|600': 'assets/fonts/ui/ReadexPro-SemiBold.ttf',
  'Readex|700': 'assets/fonts/ui/ReadexPro-Bold.ttf',
  'Amiri|400': 'assets/fonts/Amiri-Regular.ttf',
  'Amiri|700': 'assets/fonts/Amiri-Bold.ttf',
  'QCF1|400': 'assets/fonts/quran/QCF4_Hafs_01.ttf',
  'QBSML|400': 'assets/fonts/quran/QCF4_QBSML.ttf',
};

const duas = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/data/duas.json'), 'utf8'));
const dua = duas.find((d) => d.id === 'morning_bismillah_la_yadurr');
const morningCount = duas.filter((d) => d.categoryId === 'morning').length;
const page1 = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/data/mushaf/001.json'), 'utf8'));
const fatiha = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/data/quran/surah_1.json'), 'utf8'));
const fatihaEn = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/data/quran/trans/en/surah_1.json'), 'utf8'));
const tasbih = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/data/tasbih.json'), 'utf8'))[0];

const out = {
  fonts: Object.fromEntries(
    Object.entries(fonts).map(([k, p]) => [k, 'data:font/ttf;base64,' + b64(p)]),
  ),
  logo: 'data:image/png;base64,' + b64('assets/icon/app_icon.png'),
  dua: { arabic: dua.arabic, translation: dua.translation, reference: dua.reference, repeat: dua.repeat },
  morningCount,
  page1,
  verse: { arabic: fatiha.ayahs[1].text, meaning: fatihaEn.ayahs[1] },
  tasbih,
};

fs.writeFileSync(path.join(__dirname, 'assets.js'), 'window.ASSETS = ' + JSON.stringify(out) + ';');
console.log('assets.js written', (fs.statSync(path.join(__dirname, 'assets.js')).size / 1e6).toFixed(1), 'MB');
