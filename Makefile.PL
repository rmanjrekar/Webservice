use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'BankDetails::India',
    VERSION_FROM => 'lib/BankDetails/India.pm',
    PREREQ_PM    => {
        'Carp'           => 0,
        'CHI'            => 0,
        'Data::Dumper'   => 0,
        'Digest::MD5'    => 0,
        'HTTP::Message'  => 0,
        'LWP::UserAgent' => 0,
        'Moose'          => 0,
        'Sereal'         => 0,
        'JSON'           => 0,
        'XML::Simple'    => 0,
        'Cwd'            => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'Test::Exception' => '0',
        'Test::MockObject' => '0',
        'HTTP::Response' => 0,
    },
    "test" => {
        "TESTS" => "t/*.t"
    },
    META_MERGE => {
        "meta-spec" => { version => 1.0 }
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/BankDetails/India.pm',  # retrieve abstract from module
       AUTHOR         => 'manjrekarrohit76@gmail.com') : ()),
);
