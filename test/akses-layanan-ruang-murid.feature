Feature: User Mengakses Layanan di Dalam Ruang Murid
  @smoke @RP-345
  Scenario: User Mengakses Layanan di Dalam Ruang Murid
   Given user berada di halaman utama rumah pendidikan
   And user mengakses Ruang Murid
   When user mengakses Layanan Latihan Soal
   Then user akan di arahkan ke halaman Latihan Soal
