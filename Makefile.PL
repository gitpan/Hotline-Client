use ExtUtils::MakeMaker;

WriteMakefile('NAME'         => 'Hotline::Client',
              'PMLIBDIRS'    => [ 'lib', 'lib/Hotline', 'lib/Hotline/Protocol' ],
              'VERSION_FROM' => 'lib/Hotline/Client.pm');
