Feature: User Mengakses Halaman Detail Relawan Pendidikan Dari Ruang Mitra
  @smoke @RP-355
  Scenario: User Mengakses Halaman Detail Relawan Pendidikan Dari Ruang Mitra
    Given pengguna berada pada halaman /berita
    When Pengguna Klik "Paling lama"
    Then Berita diurutkan secara Ascending berdasarkan Publish Date
    When Pengguna Klik "Paling baru"
    Then Berita diurutkan secara Descending berdasarkan Publish Date
