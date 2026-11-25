class BlogPostItem {
  const BlogPostItem({
    required this.slug,
    required this.title,
    required this.category,
    required this.date,
    required this.readTime,
    required this.excerpt,
    required this.image,
    required this.paragraphs,
  });

  final String slug;
  final String title;
  final String category;
  final String date;
  final String readTime;
  final String excerpt;
  final String image;
  final List<String> paragraphs;
}

const List<BlogPostItem> sriwedariBlogPosts = [
  BlogPostItem(
    slug: 'filosofi-bedhaya-ketawang',
    title: 'Filosofi Sembilan Penari dalam Sakralitas Tari Bedhaya Ketawang',
    category: 'Filosofi Seni',
    date: '20 Oktober 2026',
    readTime: '5 menit',
    excerpt:
        'Menguak makna mistis dan simbolisme arah mata angin pada tarian sakral keraton peninggalan Sultan Agung.',
    image: '/images/tari-jawa-stage.png',
    paragraphs: [
      'Tari Bedhaya Ketawang merupakan mahakarya sakral Keraton Surakarta Hadiningrat yang ditarikan oleh sembilan penari putri terpilih dalam balutan busana dodot kampuh pengantin Jawa.',
      'Angka sembilan merepresentasikan delapan penjuru mata angin dan satu titik pusat kosmos (kiblat papat lima pancer), serta sembilan lubang hawa pada tubuh manusia yang harus diselaraskan melalui laku pengendalian diri.',
      'Setiap gerak lambat yang diiringi tembang Ketawang dan gamelan laras pelog bukan sekadar pertunjukan estetis, melainkan doa keselamatan dan ketenteraman bagi jagat raya.',
    ],
  ),
  BlogPostItem(
    slug: 'anatomi-omprok-gandrung',
    title: 'Mengenal Anatomi & Keanggunan Mahkota Omprok Gandrung Banyuwangi',
    category: 'Busana Pusaka',
    date: '14 Oktober 2026',
    readTime: '4 menit',
    excerpt:
        'Kisah ornamen garuda mungkur dan untaian manik emas yang mencerminkan keteguhan hati para penari Blambangan.',
    image: '/images/tari-gandrung-banyuwangi.png',
    paragraphs: [
      'Mahkota omprok pada busana Gandrung Banyuwangi terbuat dari kulit kerbau atau kuningan berlapis prada emas dengan ukiran Antakusuma yang memancarkan kewibawaan di atas panggung.',
      'Pada bagian belakang omprok terdapat ornamen garuda mungkur dan kembang goyang yang melambangkan kewaspadaan, keanggunan, serta rasa syukur masyarakat Osing atas hasil bumi Blambangan.',
      'Galeri Sriwedari merawat set lengkap busana Gandrung termasuk ilat-ilatan bordir emas dan jarik batik Gajah Oling agar tetap lestari untuk pementasan generasi muda.',
    ],
  ),
  BlogPostItem(
    slug: 'sejarah-wayang-orang-sriwedari',
    title: 'Perjalanan 125 Tahun Wayang Orang Sriwedari: Dari Istana ke Rakyat',
    category: 'Sejarah Lakon',
    date: '02 Oktober 2026',
    readTime: '7 menit',
    excerpt:
        'Bagaimana Sriwedari menjadi benteng terakhir pertunjukan klasik Jawa tanpa pernah memadamkan lampu panggungnya.',
    image: '/images/tari-jawa-dramatic-stage.png',
    paragraphs: [
      'Didirikan pada masa Sri Susuhunan Pakubuwana X tahun 1899 sebagai Kebon Rojo, Taman Sriwedari menjadi ruang perjumpaan seni tradisi keraton dan masyarakat Surakarta.',
      'Gedung Wayang Orang (GWO) Sriwedari menjadi saksi ketekunan para seniman lintas generasi dalam menggelar lakon epos Ramayana dan Mahabharata lengkap dengan iringan gamelan ageng.',
      'Melalui ekosistem digital Galeri Sriwedari, masyarakat kini dapat memesan tiket kursi pendopo maupun menyewa busana adat pakem dengan sistem kurasi transparan.',
    ],
  ),
];
