package Email::Sender::Maildir;
use base qw(Email::Sender);

use strict;
use warnings;

use File::Spec;
use Email::LocalDelivery;

sub dir {
  my ($self) = @_;

  $self->{dir} ||= File::Spec->catdir(File::Spec->curdir, 'Maildir');
}

sub _deliver {
  my ($self, $arg) = @_;

  my $message = Email::Abstract->new($arg->{message}->as_string);

  $message->set_header('X-EmailSender-To' => join(', ', @{ $arg->{to} }));
  $message->set_header('X-EmailSender-From' => $arg->{from});

  for my $dir (qw(cur tmp new)) {
    my $subdir = File::Spec->catdir($self->dir, $dir);
    next if -d $subdir;
    File::Path::mkpath(File::Spec->catdir($self->dir, $dir));
  }

  Email::LocalDelivery->deliver($message->as_string, $self->dir);
}

sub send_email {
  my ($self, $email, $envelope, $arg) = @_;

  my $ok = $self->_deliver(
    {
      message => $email,
      to      => $envelope->{to},
      from    => $envelope->{from},
    }
  );

  if ($ok) {
    return $self->success;
  } else {
    $self->total_failure("couldn't deliver message to Maildir");
  }
}

1;
