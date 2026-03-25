#!/usr/bin/perl
use v5.36;
use strict;
use warnings;
use feature qw(signatures say state switch);
no warnings qw(experimental::signatures experimental::smartmatch);

# Modern Perl modules
use Mojo::UserAgent;
use HTML::TreeBuilder;
use JSON::PP;
use Try::Tiny;
use Data::Dumper;
use File::Slurp;
use DateTime;
use List::Util qw(first max min sum uniq);
use Scalar::Util qw(blessed reftype looks_like_number);

# Package definition with version
package WebScraper::Advanced v1.2.3 {
   use Moo;  # Modern object system
   use Types::Standard qw(Str Int ArrayRef HashRef Maybe);
   use namespace::clean;

   # Attributes with type constraints
   has 'base_url' => (
      is       => 'ro',
      isa      => Str,
      required => 1,
   );

   has 'user_agent' => (
      is      => 'lazy',
      isa     => 'Mojo::UserAgent',
      builder => '_build_user_agent',
   );

   has 'max_retries' => (
      is      => 'rw',
      isa     => Int,
      default => 3,
   );

   has 'cache' => (
      is      => 'ro',
      isa     => HashRef,
      default => sub { {} },
   );

   has 'results' => (
      is      => 'rw',
      isa     => ArrayRef,
      default => sub { [] },
   );

   # Private method builder
   sub _build_user_agent {
      my $self = shift;
      my $ua = Mojo::UserAgent->new;
      $ua->transactor->name('WebScraper/1.0');
      $ua->request_timeout(30);
      return $ua;
   }

   # Method with signature (Perl 5.36+)
   method fetch_page($url, $options = {}) {
      my $cache_key = $self->_generate_cache_key($url, $options);

      # Check cache first
      return $self->cache->{$cache_key} if exists $self->cache->{$cache_key};

      my $attempt = 0;
      my $response;

      while ($attempt < $self->max_retries) {
         $attempt++;

         try {
            say "Fetching $url (attempt $attempt)";
            $response = $self->user_agent->get($url)->result;

            if ($response->is_success) {
               my $content = $response->body;
               $self->cache->{$cache_key} = $content;
               return $content;
            }
            else {
               die "HTTP Error: " . $response->code . " - " . $response->message;
            }
         }
         catch {
            warn "Attempt $attempt failed: $_";
            sleep($attempt * 2) if $attempt < $self->max_retries;
         };
      }

      die "Failed to fetch $url after " . $self->max_retries . " attempts";
   }

   # Method with complex regex and references
   method parse_content($html, $selectors) {
      my $tree = HTML::TreeBuilder->new;
      $tree->parse($html);
      $tree->eof;

      my $data = {};

      # Process each selector with different parsing strategies
      for my $selector_name (keys %$selectors) {
         my $selector_config = $selectors->{$selector_name};

         given ($selector_config->{type}) {
            when ('text') {
               $data->{$selector_name} = $self->_extract_text(
                  $tree, $selector_config
               );
            }
            when ('links') {
               $data->{$selector_name} = $self->_extract_links(
                  $tree, $selector_config
               );
            }
            when ('table') {
               $data->{$selector_name} = $self->_extract_table_data(
                  $tree, $selector_config
               );
            }
            default {
               warn "Unknown selector type: $selector_config->{type}";
            }
         }
      }

      $tree->delete;
      return $data;
   }

   # Private method with complex data manipulation
   method _extract_text($tree, $config) {
      my @elements = $tree->look_down($config->{selector}->%*);
      my @texts;

      for my $element (@elements) {
         my $text = $element->as_text;

         # Apply transformations
         if ($config->{transform}) {
            for my $transform (@{$config->{transform}}) {
               given ($transform->{type}) {
                  when ('trim') {
                     $text =~ s/^\s+|\s+$//g;
                  }
                  when ('lowercase') {
                     $text = lc($text);
                  }
                  when ('regex') {
                     my $pattern = $transform->{pattern};
                     my $replacement = $transform->{replacement} // '';
                     $text =~ s/$pattern/$replacement/g;
                  }
               }
            }
         }

         push @texts, $text if $text;
      }

      return $config->{single} ? $texts[0] : \@texts;
   }

   # Method demonstrating advanced Perl features
   method _extract_links($tree, $config) {
      my @links = $tree->look_down('_tag' => 'a', 'href' => qr/.+/);
      my @processed_links;

      for my $link (@links) {
         my $href = $link->attr('href');
         my $text = $link->as_text;

         # Resolve relative URLs
         if ($href =~ m{^/}) {
            $href = $self->base_url . $href;
         }
         elsif ($href !~ m{^https?://}) {
            next; # Skip invalid links
         }

         # Filter by pattern if specified
         if ($config->{pattern}) {
            next unless $href =~ /$config->{pattern}/;
         }

         push @processed_links, {
            url  => $href,
            text => $text,
            domain => $self->_extract_domain($href),
         };
      }

      return \@processed_links;
   }

   # Method with hash slices and complex data structures
   method _extract_table_data($tree, $config) {
      my @tables = $tree->look_down('_tag' => 'table');
      return [] unless @tables;

      my $table = $tables[0]; # Take first table
      my @rows = $table->look_down('_tag' => 'tr');
      my @data;

      # Extract headers
      my $header_row = shift @rows;
      my @headers = map { $_->as_text } $header_row->look_down('_tag' => qr/^th|td$/);

      # Process data rows
      for my $row (@rows) {
         my @cells = $row->look_down('_tag' => 'td');
         next unless @cells;

         my %row_data;
         for my $i (0 .. $#headers) {
            my $value = $cells[$i] ? $cells[$i]->as_text : '';
            $value =~ s/^\s+|\s+$//g; # trim

            # Convert numbers
            if (looks_like_number($value)) {
               $value = $value + 0; # Force numeric context
            }

            $row_data{$headers[$i]} = $value;
         }

         push @data, \%row_data;
      }

      return \@data;
   }

   # Utility methods with different perl idioms
   method _generate_cache_key($url, $options) {
      my $key_data = {
         url => $url,
         %$options
      };

      # Create a simple hash key from the data
      my $json = JSON::PP->new->canonical->encode($key_data);
      return unpack('H*', $json); # Convert to hex string
   }

   method _extract_domain($url) {
      return $1 if $url =~ m{^https?://([^/]+)};
      return '';
   }

   # Method that demonstrates closures and higher-order functions
   method filter_results($criteria_sub) {
      my @filtered = grep { $criteria_sub->($_) } @{$self->results};
      return \@filtered;
   }

   # Export functionality with file I/O
   method save_to_file($filename, $format = 'json') {
      my $data = {
         scraped_at => DateTime->now->iso8601,
         base_url   => $self->base_url,
         results    => $self->results,
         cache_size => scalar keys %{$self->cache},
      };

      given ($format) {
         when ('json') {
            my $json = JSON::PP->new->pretty->encode($data);
            write_file($filename, $json);
         }
         when ('dumper') {
            my $dumper = Data::Dumper->new([$data], ['scraped_data']);
            $dumper->Indent(1)->Sortkeys(1);
            write_file($filename, $dumper->Dump);
         }
         default {
            die "Unsupported format: $format";
         }
      }

      say "Data saved to $filename";
   }
}

# Standalone functions demonstrating various Perl features
sub analyze_text_content {
   my ($text) = @_;

   # Word frequency analysis using hash
   my %word_freq;
   my @words = split /\W+/, lc($text);

   $word_freq{$_}++ for grep { length > 3 } @words;

   # Sort by frequency (descending)
   my @sorted_words = sort { $word_freq{$b} <=> $word_freq{$a} } keys %word_freq;

   return {
      total_words => scalar(@words),
      unique_words => scalar(keys %word_freq),
      most_common => [@sorted_words[0..9]], # Top 10
      word_freq => \%word_freq,
   };
}

# Function with prototypes and different parameter handling
sub process_urls ($) {
   my $urls_ref = shift;
   my @results;

   # Process URLs in parallel using fork (simplified)
   for my $url (@$urls_ref) {
      # URL validation with regex
      unless ($url =~ m{^https?://[^\s/$.?#].[^\s]*$}) {
         warn "Invalid URL: $url";
         next;
      }

      push @results, {
         url => $url,
         domain => ($url =~ m{^https?://([^/]+)})[0],
         scheme => ($url =~ m{^(https?)})[0],
         processed_at => time(),
      };
   }

   return wantarray ? @results : \@results;
}

# Complex regex function
sub extract_email_addresses {
   my ($text) = @_;

   # Comprehensive email regex
   my $email_pattern = qr{
      \b                          # Word boundary
      [A-Za-z0-9]                 # First character
      [A-Za-z0-9._%-]*            # Middle part
      [A-Za-z0-9]                 # Last character before @
      @                           # @ symbol
      [A-Za-z0-9]                 # Domain start
      [A-Za-z0-9.-]*              # Domain middle
      [A-Za-z0-9]                 # Domain end
      \.[A-Za-z]{2,}              # TLD
      \b                          # Word boundary
   }x; # Extended regex with comments

   my @emails = $text =~ /$email_pattern/g;
   return uniq(@emails); # Remove duplicates
}

# Main execution block
if ($0 eq __FILE__) {
   # Configuration hash with anonymous subroutines
   my $config = {
      scraping_rules => {
         title => {
            type => 'text',
            selector => { '_tag' => 'title' },
            single => 1,
         },

         headlines => {
            type => 'text',
            selector => { '_tag' => 'h1' },
            transform => [
               { type => 'trim' },
               { type => 'regex', pattern => qr/\s+/, replacement => ' ' },
            ],
         },

         external_links => {
            type => 'links',
            pattern => qr{^https?://(?!example\.com)},
         },

         data_table => {
            type => 'table',
         },
      },

      output_options => {
         format => 'json',
         filename => 'scraped_data_' . time() . '.json',
      },
   };

   # Command line argument processing
   my $target_url = $ARGV[0] // 'https://example.com';

   say "=== Advanced Web Scraper ===";
   say "Target URL: $target_url";

   try {
      # Create scraper instance
      my $scraper = WebScraper::Advanced->new(
         base_url => $target_url,
         max_retries => 3,
      );

      # Fetch and parse content
      my $html = $scraper->fetch_page($target_url);
      my $parsed_data = $scraper->parse_content($html, $config->{scraping_rules});

      # Store results
      $scraper->results([$parsed_data]);

      # Analyze text content if we have headlines
      if ($parsed_data->{headlines} && @{$parsed_data->{headlines}}) {
         my $combined_text = join(' ', @{$parsed_data->{headlines}});
         my $analysis = analyze_text_content($combined_text);
         $parsed_data->{text_analysis} = $analysis;
      }

      # Extract emails from page content
      my @emails = extract_email_addresses($html);
      $parsed_data->{found_emails} = \@emails if @emails;

      # Display results
      say "\n=== Results ===";
      say "Title: " . ($parsed_data->{title} // 'N/A');
      say "Headlines found: " . (@{$parsed_data->{headlines}} // 0);
      say "External links: " . (@{$parsed_data->{external_links}} // 0);
      say "Emails found: " . (@emails // 0);

      # Save results
      $scraper->save_to_file(
         $config->{output_options}{filename},
         $config->{output_options}{format}
      );

      # Demonstrate filtering with closure
      my $long_headlines = $scraper->filter_results(sub {
            my $result = shift;
            return 0 unless $result->{headlines};
            return grep { length($_) > 50 } @{$result->{headlines}};
         });

      say "Long headlines: " . @$long_headlines;

   }
   catch {
      die "Scraping failed: $_";
   };
}

# END block for cleanup
END {
   say "Script completed at " . localtime();
}

# Here-doc example for templates
my $html_template = <<'EOF';
<!DOCTYPE html>
<html>
<head>
<title>Scraping Results</title>
</head>
<body>
<h1>Results for: {{URL}}</h1>
<div class="content">{{CONTENT}}</div>
</body>
</html>
EOF
