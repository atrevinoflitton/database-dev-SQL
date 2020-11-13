/* Analia Trevino-Flitton
DBST 651:9040
Fall 2020
Cloud Genome: DDL Script
*/

-----------------------------------------------------------------------------------------        
-- Drop all objects in case they already exist
-----------------------------------------------------------------------------------------        

DROP TABLE organism CASCADE CONSTRAINTS;
DROP TABLE ref_literature CASCADE CONSTRAINTS;
DROP TABLE genome CASCADE CONSTRAINTS;
DROP TABLE gene CASCADE CONSTRAINTS;
DROP TABLE protein CASCADE CONSTRAINTS; 
 
DROP SEQUENCE seq_gen_ref; 
DROP SEQUENCE seq_gen_org; 
DROP SEQUENCE seq_gen_genome; 
DROP SEQUENCE seq_gen_gene;
DROP SEQUENCE seq_gen_pro;  

-----------------------------------------------------------------------------------------        
-- Create tables for all objects with foreign key constraints
-----------------------------------------------------------------------------------------      
  
CREATE TABLE ref_literature (
	ref_id int  NOT NULL CONSTRAINT PK_ref_id PRIMARY KEY,
	pubmed_id varchar2 (255),
	journal varchar2 (255) NOT NULL,
	journal_volume int,
	article_title varchar2 (255) NOT NULL,
	pub_date date NOT NULL,
	org_id varchar2 (255)    
    );
    
CREATE TABLE organism (
	org_id varchar2 (255)  NOT NULL CONSTRAINT PK_org_id PRIMARY KEY,
	scientific_name varchar2 (255) NOT NULL,
	org_type varchar2 (255) NOT NULL,
	host varchar2 (255),
	lineage varchar2 (255) NOT NULL,
    	ref_id int NOT NULL,
	genome_id varchar2 (255),
	
CONSTRAINT FK_org_ref_id            
    FOREIGN KEY(ref_id)      REFERENCES ref_literature(ref_id),

CONSTRAINT FK_ref_org_id
	FOREIGN KEY(org_id) REFERENCES organism(org_id)
    );

CREATE TABLE genome (
	genome_id varchar2 (255) NOT NULL CONSTRAINT PK_genome_id PRIMARY KEY,
	fasta_id varchar2 (255),
	dna_seq varchar2 (255) NOT NULL,
	dna_length int NOT NULL,
	gc_content number,
	org_id varchar2 (255) NOT NULL,
	gene_id varchar2 (255),
	
CONSTRAINT FK_genome_org_id            
    FOREIGN KEY(org_id)     REFERENCES organism(org_id),
    
CONSTRAINT FK_org_genome_id
	FOREIGN KEY(genome_id) REFERENCES genome(genome_id)
    );
 
CREATE TABLE gene (
	gene_id varchar2 (255)  NOT NULL CONSTRAINT PK_gene_id  PRIMARY KEY,
	gene_type varchar2 (255),
	gene_symbol varchar2 (255),
	gene_description varchar2 (255),
	last_update date,
	genome_id varchar2 (255) NOT NULL,
	protein_id varchar2 (255),

CONSTRAINT FK_gene_genome_id
    FOREIGN KEY(genome_id)      REFERENCES genome(genome_id),
    
CONSTRAINT FK_genome_gene_id
	FOREIGN KEY(gene_id) REFERENCES gene(gene_id)
    );
      
CREATE TABLE protein (
	protein_id varchar2 (255) NOT NULL CONSTRAINT  PK_protein_id PRIMARY KEY,
	pfam varchar2 (255),
	protein_seq varchar2 (255) NOT NULL,
	region_name varchar2 (255),
	mol_weight number (38),
	gene_id varchar2 (255) NOT NULL,

CONSTRAINT FK_pro_gene_id              
    FOREIGN KEY(gene_id)        REFERENCES gene(gene_id),
                                        
CONSTRAINT FK_gene_protein_id
    FOREIGN KEY(protein_id) REFERENCES protein(protein_id)
    );

-----------------------------------------------------------------------------------------        
-- Alter table to add audit columns 
-----------------------------------------------------------------------------------------      
ALTER TABLE ref_literature ADD(
	created_by varchar2 (30),
	date_created date,  
	modified_by varchar2(30),
	date_modified date );

ALTER TABLE organism ADD(
	created_by varchar2 (30),
	date_created date,  
	modified_by varchar2(30),
	date_modified date );

ALTER TABLE genome ADD(
	created_by varchar2 (30),
	date_created date,  
	modified_by varchar2(30),
	date_modified date );

ALTER TABLE gene ADD(
	created_by varchar2 (30),
	date_created date,  
	modified_by varchar2(30),
	date_modified date );

ALTER TABLE protein ADD(
	created_by varchar2 (30),
	date_created date,  
	modified_by varchar2(30),
	date_modified date );
    
-----------------------------------------------------------------------------------------        
/* Views for each table provide improved accessability for use by specific departments 
 or teams and eliminate the need to specify each individual attribute. 
 Saves employees time with less coding and bug troubleshooting. */
----------------------------------------------------------------------------------------- 

--Business Purpose: To provide a quick query for relevant reference literature information 
CREATE OR REPLACE VIEW VW_ref_literature AS
	SELECT pubmed_id, article_title, journal, pub_date
	FROM ref_literature;

--Business Purpose: Provides a fast query to access the organism's information in a grouped fashion
CREATE OR REPLACE VIEW VW_organism AS
	SELECT org_id, scientific_name, org_type, lineage
	FROM organism;

--Business Purpose: A simple query for many of the genome's attrubutes
CREATE OR REPLACE VIEW VW_genome AS
	SELECT genome_id, dna_seq, dna_length
	FROM genome;

--Business Purpose: A streamlined query to view all the gene's informaiton at once
CREATE OR REPLACE VIEW VW_gene AS
	SELECT gene_id, gene_type, gene_symbol, gene_description
	FROM gene;

--Business Purpose: A single query to provide the protein attributes
CREATE OR REPLACE VIEW VW_protein AS
	SELECT protein_id, pfam, protein_seq, region_name
	FROM protein;
       
-----------------------------------------------------------------------------------------        
-- Index for natural key, FK & frequently queried
-----------------------------------------------------------------------------------------      

CREATE UNIQUE INDEX UX_org_sci_name ON organism(scientific_name);

CREATE UNIQUE INDEX  UX_genome_fasta_id ON genome(fasta_id);

CREATE UNIQUE INDEX  UX_pro_pro_seq ON protein(protein_seq);

CREATE UNIQUE INDEX  UX_ref_lit_article_title ON ref_literature(article_title);

CREATE UNIQUE INDEX  UX_ref_lit_pubmed_id ON ref_literature(pubmed_id);

-- Foreign Key Index
CREATE UNIQUE INDEX  UX_org_ref_id_FK ON organism(ref_id);

CREATE UNIQUE INDEX UX_ref_org_id_FK ON ref_literature(org_id);

CREATE UNIQUE INDEX UX_genome_org_id_FK ON genome(org_id);

CREATE UNIQUE INDEX UX_org_genome_id_FK ON organism(genome_id);

CREATE UNIQUE INDEX UX_gene_genome_id_FK ON gene(genome_id);

CREATE UNIQUE INDEX UX_genome_gene_id_FK ON genome(gene_id);

CREATE UNIQUE INDEX UX_gene_protein_id_FK ON gene(protein_id);

-----------------------------------------------------------------------------------------        
-- Sequence generators for triggers
----------------------------------------------------------------------------------------- 

CREATE SEQUENCE seq_gen_ref;

CREATE SEQUENCE seq_gen_org; 

CREATE SEQUENCE seq_gen_genome;

CREATE SEQUENCE seq_gen_gene;

CREATE SEQUENCE seq_gen_pro;  

-----------------------------------------------------------------------------------------        
-- Triggers
----------------------------------------------------------------------------------------- 

/* Business Purpose: To ensure each piece of reference literature has a unique corresponding
   reference ID (primary key) if one is not provided */

CREATE OR REPLACE TRIGGER ref_lit_TRG  
	BEFORE INSERT OR UPDATE ON ref_literature  
	FOR EACH ROW
	BEGIN  
	IF :NEW.ref_id IS NULL THEN
	:NEW.ref_id := genseq_ref.NEXTVAL;
	END IF;

IF INSERTING THEN
	IF :NEW.created_by IS NULL THEN :NEW.created_by := USER; END IF;
	IF :NEW.date_created IS NULL THEN :NEW.date_created := SYSDATE; END IF;
  	END IF;

IF INSERTING OR UPDATING THEN    
	IF :NEW.modified_by IS NULL THEN :NEW.modified_by := USER; END IF;    
	IF :NEW.date_modified IS NULL THEN :NEW.date_modified := SYSDATE; END IF;  		
    END IF;END;
	/  

-- Business Purpose: Generates a required organism ID (primary key) if one is not listed to ensure constraints are met

CREATE OR REPLACE TRIGGER org_TRG  
	BEFORE INSERT OR UPDATE ON organism  
	FOR EACH ROW
	BEGIN  
	IF :NEW.org_id IS NULL THEN
	:NEW.org_id := genseq_org.NEXTVAL;
	END IF;

IF INSERTING THEN
	IF :NEW.created_by IS NULL THEN :NEW.created_by := USER; END IF;
	IF :NEW.date_created IS NULL THEN :NEW.date_created := SYSDATE; END IF;
  	END IF;

IF INSERTING OR UPDATING THEN    
	IF :NEW.modified_by IS NULL THEN :NEW.modified_by := USER; END IF;    
	IF :NEW.date_modified IS NULL THEN :NEW.date_modified := SYSDATE; END IF;  		
    END IF;END;
	/    

-- Business Purpose: Provides a random sequence for the gene ID ( primary key ) for the Gene table if one is not provided

CREATE OR REPLACE TRIGGER gene_TRG  
	BEFORE INSERT OR UPDATE ON gene  
	FOR EACH ROW
	BEGIN  
	IF :NEW.gene_id IS NULL THEN
	:NEW.gene_id := genseq_gene.NEXTVAL;
	END IF;

IF INSERTING THEN
	IF :NEW.created_by IS NULL THEN :NEW.created_by := USER; END IF;
	IF :NEW.date_created IS NULL THEN :NEW.date_created := SYSDATE; END IF;
  	END IF;

IF INSERTING OR UPDATING THEN    
	IF :NEW.modified_by IS NULL THEN :NEW.modified_by := USER; END IF;    
	IF :NEW.date_modified IS NULL THEN :NEW.date_modified := SYSDATE; END IF;  		
    END IF;END;
	/ 

-- Business Purpose: Gives every protein a unquie locator ID if one is not provided

CREATE OR REPLACE TRIGGER pro_TRG  
	BEFORE INSERT OR UPDATE ON protein  
	FOR EACH ROW
	BEGIN  
	IF :NEW.protein_id IS NULL THEN
	:NEW.protein_id := genseq_pro.NEXTVAL;
	END IF;

IF INSERTING THEN
	IF :NEW.created_by IS NULL THEN :NEW.created_by := USER; END IF;
	IF :NEW.date_created IS NULL THEN :NEW.date_created := SYSDATE; END IF;
  	END IF;

IF INSERTING OR UPDATING THEN    
	IF :NEW.modified_by IS NULL THEN :NEW.modified_by := USER; END IF;    
	IF :NEW.date_modified IS NULL THEN :NEW.date_modified := SYSDATE; END IF;	
    END IF;END;
	/  

----------------------------------------------------------------------------------------- 
/* Analia Trevino-Flitton
DBST 651:9040
Fall 2020
Cloud Genome: DML Script
*/


-- Populate all Tables
----------------------------------------------------------------------------------------- 
-- 1

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (14755, 10482585, 'Nature', '18', 'A phylogenetically conserved hairpin-type 3 untranslated region pseudoknot functions in coronavirus RNA replication', TO_DATE('08-Oct-1999') );

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (78884, 15630477, 'PLoS Biol.', '3', 'The structure of a rigorously conserved RNA element within the SARS virus genome', TO_DATE('18-Jan-2005') );

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (96657, 15680415, 'Virology', '332', 'Programmed ribosomal frameshifting in decoding the SARS-CoV genome', TO_DATE('20-Feb-2005') );

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (74441, 32015508, 'Nature', '579', 'A new coronavirus associated with human respiratory disease in China', TO_DATE('01-Mar-2020') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage)
VALUES (74441,'NC_045512', 'Orthocoronavirinae', 'Virus', 'Homo sapien', 'Viruses; Riboviria; Orthornavirae; Pisuviricota; Pisoniviricetes; Nidovirales; Cornidovirineae; Coronaviridae; Orthocoronavirinae; Betacoronavirus; Sarbecovirus; Severe acute respiratory syndrome-related coronavirus' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ('NC_045512.2', 'NC_045512.2 Severe acute respiratory syndrome coronavirus 2 isolate Wuhan-Hu-1, complete genome', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG
', 25699,  38, 'NC_045512' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ( 'GU280_gp01', 'protein coding', 'ORF1ab', 'ORF1a polyprotein;ORF1ab polyprotein', TO_DATE('04-Nov-2020'), 'NC_045512.2' );

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('YP_009725297.1', 'pfam11501', 'meslvpgfne kthvqlslpv lqvrdvlvrg fgdsveevls earqhlkdgt cglvevekgv', 'Nsp1', 19644,'GU280_gp01' );

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('YP_009725300', 'pfam16348', 'rsdvllpltq ynrylalynk ykyfsgamdt tsyreaacch lakalndfsn', 'Corona_NSP4_C', 56184, 'GU280_gp01' );

-------------------------------------------------------------------------------------

-- 2

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (59667, 26262818, 'ISME J.', '10', 'Deciphering the bat virome catalog to better understand the ecological diversity of bat viruses and the bat origin of emerging infectious diseases', TO_DATE('05-Mar-2016') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage)
VALUES (59667, 'NC_025217', 'Bat Hp-betacoronavirus/Zhejiang2013', 'Virus', 'Hipposideros pratti', 'Viruses; Riboviria; Orthornavirae; Pisuviricota; Pisoniviricetes; Nidovirales; Cornidovirineae; Coronaviridae; Orthocoronavirinae; Betacoronavirus; Hibecovirus; Bat Hp-betacoronavirus Zhejiang2013' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ( 'NC_025217.1', 'NC_025217.1 Bat Hp-betacoronavirus/Zhejiang2013, complete genome', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG
', 7325,  45, 'NC_025217' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ( 'NA39_gp6','ribosomal_slippage', 'ORF1ab', 'ORF1ab polyprotein is cleaved to yield the RNA-dependent RNA polymerase and other nonstructural proteins; polyprotein pp1ab', TO_DATE('25-Aug-2020'), 'NC_025217.1');

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('YP_009072438', 'pfam11501', 'kvrqlckll rgtkaltevi plteeaelel aenreilkep vhgvyydpsk dliaeiqkqg', 'Nsp1', 17821, 'NA39_gp6' );

-----------------------------------------------------------------------------------

-- 3

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (16344, 10073695, 'J Gen Virol.', '80', 'Characterization of the L gene and 5 trailer region of Ebola virus', TO_DATE('10-Feb-1999') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage)
VALUES (16344,'NC_002549', 'Zaire ebolavirus', 'Virus', 'Homo sapien', 'Viruses; Riboviria; Orthornavirae; Negarnaviricota; Haploviricotina; Monjiviricetes; Mononegavirales; Filoviridae; Ebolavirus.' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ( 'NC_002549.1', 'NC_002549.1 Zaire ebolavirus isolate Ebola virus/H.sapiens-tc/COD/1976/Yambuku-Mayinga, complete genome', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG
', 899,  36, 'NC_002549' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ( 'ZEBOVgp1','protein coding', 'NP', 'nucleoprotein', TO_DATE('4-Jan-2020'), 'NC_002549.1');

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('NP_066243.1', 'pfam05505', 'kkekvyl awvpahkgig gneqvdklvs agirkvlfld gidkaqdeh', 'Nsp1', 83156, 'ZEBOVgp1' );

----------------------------------------------------------------------------------

-- 4

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (47781, 26862926, 'N Engl J med.', '374', 'Zika Virus Associated with Microcephaly', TO_DATE('10-Mar-2016') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage)
VALUES (47781, 'NC_035889', 'Zika virus', 'Virus', 'Homo sapien', 'Viruses; Riboviria; Orthornavirae; Kitrinoviricota; Flasuviricetes;Amarillovirales; Flaviviridae; Flavivirus' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ( 'NC_035889.1', 'NC_035889.1 Zika virus isolate ZIKV/H. sapiens/Brazil/Natal/2015, complete genome', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG', 2777,  23, 'NC_035889' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ( 'CPG35_gp1','protein coding', 'POLY', 'polyprotein', TO_DATE('1-Aug-2020'), 'NC_035889.1');

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('YP_009428568', 'pfam01003', 'LRRVYNINGFDEVKPMALCALHYCEDCGMEMWCHSNFEEAYCPAEDKAEPGN', 'Flavi_capsid', 19096, 'CPG35_gp1' );

--------------------------------------------------------------------------------

-- 5

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (77881, 9362478, 'EMBO J.', '16', 'Signal peptide fragments of preprolactin and HIV-1 p-gp160 interact with calmodulin', TO_DATE('17-Nov-1997') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage )
VALUES (77881,'NC_001802', 'Human immunodeficiency virus 1 (HIV-1)', 'Virus', 'Homo sapien', ' Viruses; Riboviria; Pararnavirae; Artverviricota; Revtraviricetes; Ortervirales; Retroviridae; Orthoretrovirinae; Lentivirus' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ('NC_001802.1', 'NC_001802.1 Human immunodeficiency virus 1, complete genome', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG
', 8956,  38, 'NC_001802' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ( 'HIV1gp1', 'protein coding', 'gag-pol', 'Gag-Pol', TO_DATE('27-Jun-2020'), 'NC_001802.1' );

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('NP_789740.1', 'pfam00077', 'qefgipy npqsqgvves mnkelkkiig qvrdqaehlk tavqmavfih nfkrkggigg', 'RT_Rtv', 112754, 'HIV1gp1' );

--------------------------------------------------------------------------------

-- 6

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (24498, 3018124, 'N Engl J med.', '374', 'The complete DNA sequence of varicella-zoster virus', TO_DATE('26-Sep-1986') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage)
VALUES (24498, 'NC_001348', 'Human alphaherpesvirus 3 (HHV-3)','Virus' , 'Homo sapien', 'Viruses; Duplodnaviria; Heunggongvirae; Peploviricota;Herviviricetes; Herpesvirales; Herpesviridae; Alphaherpesvirinae; Varicellovirus.' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ( 'NC_001348.1' , 'NC_001348.1 Human herpesvirus 3, complete genome', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG', 2787,  65, 'NC_001348' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ('HHV3_gp01' ,'protein coding', 'ORF0', 'membrane protein UL56', TO_DATE('3-Mar-2019'), 'NC_001348.1');

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('YP_053044' , 'UL56 family' , 'hysrrp gtppvtltutcbbss psmddvatpi pylptyaeav adapppyrsr eslvfsppl' , 'ORF0' , 39456 , 'HHV3_gp01' );

--------------------------------------------------------------------------------

-- 7

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (35512, 8805245, 'Curr Biol', '6', 'Metabolism and evolution of Haemophilus influenzae deduced from a whole-genome comparison with Escherichia coli', TO_DATE('10-Mar-1996') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage )
VALUES (35512, 'NC_000907', 'Haemophilus influenzae', 'Bacteria', 'Homo sapien', 'Bacteria; Proteobacteria; Gammaproteobacteria; Pasteurellales; Pasteurellaceae; Haemophilus' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ( 'NC_000907.1', 'NC_000907.1 Haemophilus influenzae Rd KW20, complete sequence', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG
', 65721,  24, 'NC_000907' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ( 'aroG', 'protein coding', 'aroG', 'equivalog', TO_DATE('23-Jun-2020'), 'NC_000907.1' );

INSERT INTO protein (protein_id, protein_seq, mol_weight, gene_id)
VALUES ('NP_7849740.1', 'anddsdyytocdqvlppiallYYOOekypaseqaaalvkahniihgkddrllvvi', 38994, 'aroG' );

--------------------------------------------------------------------------------

-- 8

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (02257, 28840828, 'Euro Surveill.', '22', 'Imported case of Middle East respiratory syndrome coronavirus (MERS-CoV) infection from Oman to Thailand, June 2015', TO_DATE('17-Aug-2017') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage )
VALUES (02257,'KT2254762', 'Middle East respiratory syndrome-related coronavirus (MERS-CoV)', 'Virus', 'Homo sapien', 'Viruses; Riboviria; Orthornavirae; Pisuviricota; Pisoniviricetes; Nidovirales; Cornidovirineae; Coronaviridae; Orthocoronavirinae; Betacoronavirus; Merbecovirus.' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ('KT225476.2', 'KT225476.2 Middle East respiratory syndrome coronavirus isolate MERS-CoV/THA/CU/17_06_2015, complete genome', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG
', 21529,  42, 'KT2254762' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ( 'SUD-M', 'protein coding', 'SUD-M', 'SUD-M', TO_DATE('15-Apr-2020'), 'KT225476.2' );

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('NP_789880.1', 'pfam1661', 'SVLACYNGRPYUTNTWEERBTAUADDIITGTFTDSFVVMRPNYTIKGSFLCGSCGS', 'Corona_S2', 25511, 'SUD-M' );

--------------------------------------------------------------------------------

-- 9

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES( 43699, 1326820, 'Virology', '190', 'Molecular cloning of a novel human papillomavirus (type 60) from a plantar cyst with characteristic pathological changes', TO_DATE('01-Sep-1992') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage )
VALUES (43699, 'NC_001693', 'Human papillomavirus type 60', 'Virus', 'Homo sapien', ' Viruses; Monodnaviria; Shotokuvirae; Cossaviricota;Papovaviricetes; Zurhausenvirales; Papillomaviridae;Firstpapillomavirinae; Gammapapillomavirus' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ( 'NC_001693.1', 'NC_001693.1 Human papillomavirus type 60, complete genome', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG', 14879,  27, 'NC_001693' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ( 'E6_ght', 'protein coding', 'E6', 'transforming protein E6', TO_DATE('15-Aug-2018'), 'NC_001693.1' );

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('NP_043437', 'pfam00518', 'qmeedrfpt tvadycsefd iplkdlklkc vfcrfylteq qlaaf', 'E6', 16679, 'E6_ght' );

--------------------------------------------------------------------------------

-- 10

INSERT INTO ref_literature (ref_id, pubmed_id, journal, journal_volume, article_title, pub_date)
VALUES (89214, 2552166, 'J. Virol', '63', 'Human papillomavirus type 48', TO_DATE('12-Nov-1989') );

INSERT INTO organism (ref_id, org_id, scientific_name, org_type, host, lineage )
VALUES (89214, 'NC_001690', 'Human papillomavirus type 48', 'Virus', 'Homo sapien', 'Viruses; Monodnaviria; Shotokuvirae; Cossaviricota;Papovaviricetes; Zurhausenvirales; Papillomaviridae;Firstpapillomavirinae; Gammapapillomavirus' );

INSERT INTO genome ( genome_id, fasta_id, dna_seq, dna_length, gc_content, org_id)
VALUES ('NC_001690.1', 'NC_001690.1 Human papillomavirus type 48, complete genome', 'ATTAAAGGTTTATACCTTCCCAGGTAACAAACCAACCAACTTTCGATCTCTTGTAGATCTGTTCTCTAAA
CGAACTTTAAAATCTGTGTGGCTGTCACTCGGCTGCATGCTTAGTGCACTCACGCAGTATAATTAATAAC
TAATTACTGTCGTTGACAGGACACGAGTAACTCGTCTATCTTCTGCAGGCTGCTTACGGTTTCGTCCGTG', 7100,  44, 'NC_001690' );

INSERT INTO gene ( gene_id, gene_type, gene_symbol, gene_description, last_update, genome_id  )
VALUES ( 'E1', 'protein coding', 'E1', 'replication protein E1', TO_DATE('15-Aug-2018'), 'NC_001690.1' );

INSERT INTO protein (protein_id, pfam, protein_seq, region_name, mol_weight, gene_id)
VALUES ('NP_043418', 'pfam00524', 'qngaec elnsilrsnn iratvlckfk dkfgvsfnel', 'E1', 2744, 'E1' );

--------------------------------------------------------------------------------
-- All Data Dictionary
--------------------------------------------------------------------------------
SELECT TABLE_NAME FROM USER_TABLES;
SELECT OBJECT_NAME, STATUS, CREATED, LAST_DDL_TIME FROM USER_OBJECTS;


/* Analia Trevino-Flitton
DBST 651:9040
Fall 2020
Cloud Genome: 20 SQL Statements- 8 Advanced Queries
*/
-----------------------------------------------------------------------------------------         
/* Query 1: Select all columns and all rows from one table

   Business Purpose: This selects all the row information from the gene table. */
----------------------------------------------------------------------------------------- 
SELECT *
FROM 
	gene;

-----------------------------------------------------------------------------------------        
/* Query 2: Select 5 columns and all rows from one table.

   Business Purpose: This provides information about all organisms currently in the  
   database. */
----------------------------------------------------------------------------------------- 
SELECT 
	org_id, scientific_name, org_type, host, lineage
FROM 
	organism;

-----------------------------------------------------------------------------------------        
/* Query 3: Select all columns and all rows from one view.

   Business Purpose: This shows all the gene information in the gene view, it is a faster 
   query than selecting specific gene information. */
----------------------------------------------------------------------------------------- 
SELECT * 
FROM
	VW_gene;

-----------------------------------------------------------------------------------------        
/* Query 4: Using a join on 2 tables, select all columns and all rows from the tables 
   without the use of a Cartesian product.

   Business Purpose: Joins the protein and gene tables. */
----------------------------------------------------------------------------------------- 
SELECT *
FROM 
	gene 
LEFT JOIN protein ON gene.gene_id = protein.gene_id;

-----------------------------------------------------------------------------------------        
/* Query 5: Select and order data retrieved from one table.

   Business Purpose: lists the proteins in the protein table in order of the highest
   molecular weight to the lowest. */
----------------------------------------------------------------------------------------- 
SELECT *
FROM 
	protein
ORDER BY
	 mol_weight DESC;

-----------------------------------------------------------------------------------------      
/* Query 6: Using a join on 3 tables, select 5 columns from the 3 tables. Use syntax that
   would limit the output to 10 rows.

   Business Purpose: This selects the an organism's org ID, scientific name, ref ID, the 
   genome ID and it's genome length. */
----------------------------------------------------------------------------------------- 
SELECT 
	rl.ref_id, 
	o.org_id, o.scientific_name, 
	gm.genome_id, gm.dna_length
FROM 
	ref_literature rl
JOIN organism o	ON o.ref_id = rl.ref_id
JOIN genome gm	ON gm.org_id = o.org_id
WHERE 
	ROWNUM <= 10;

-----------------------------------------------------------------------------------------        
/* Query 7: Select distinct rows using joins on 3 tables.
  
   Business Purpose: This selects distinctly different values from the gene symbol, protein 
   family, protein ID, and the genome's fasta ID. */
----------------------------------------------------------------------------------------- 
SELECT DISTINCT 
	g.gene_symbol, p.pfam, p.protein_id, gm.fasta_id
FROM 
	genome gm
JOIN gene g ON g.genome_id =  gm.genome_id
JOIN protein p ON p.gene_id = g.gene_id;

-----------------------------------------------------------------------------------------        
/* Query 8: Use group by & having in a select statement using one or more tables.
  
   Business Purpose: Lists gene symbol, gene ID, protein associated with gene, protein 
   family, and orders by lightest to heaviest molecular weight. */
----------------------------------------------------------------------------------------- 
SELECT 
	g.gene_symbol, g.gene_id, p.protein_id,p.pfam, p.mol_weight
FROM 
	protein p JOIN gene g ON p.gene_id = g.gene_id
GROUP BY 
	g.gene_symbol, g.gene_id, p.protein_id,p.pfam, p.mol_weight
HAVING
	p.mol_weight >= 2000
ORDER BY
	 mol_weight ASC;

-----------------------------------------------------------------------------------------    

/* Query 9: Use IN clause to select data from one or more tables.
   
   Business Purpose: Shows the reference ID, scietific name and organism host for organism's 
   that have been published in the journals Nature and Virology. */
----------------------------------------------------------------------------------------- 
SELECT 
	rl.ref_id, rl.journal, o.scientific_name, o.host
FROM 
	ref_literature rl
JOIN organism o ON o.ref_id = rl.ref_id

WHERE journal IN ('Nature', 'Virology');

-----------------------------------------------------------------------------------------     
/* Query 10: Select Length of one column from one table (use Length function)

   Business Purpose: Shows the length of the journal titles */
----------------------------------------------------------------------------------------- 
SELECT 
	LENGTH(journal) AS "Journal Length", journal
FROM 
	ref_literature;

-----------------------------------------------------------------------------------------     

/* Query 11: use the SLQ DELETE statement to delete one record from one table
  
  Business Purpose: This deletes the protein family with the value of pfam01003 */
----------------------------------------------------------------------------------------- 
SELECT pfam FROM protein;
DELETE FROM 
	protein
WHERE 
	pfam = 'pfam01003';
SELECT pfam FROM protein;
COMMIT;
ROLLBACK;

-----------------------------------------------------------------------------------------        
/* Query 12: use the SQL UPDATE statement to change some data

   Business Purpose: This updates all the organism's type to Prokaryote if data
   reclassification were to occur. */
----------------------------------------------------------------------------------------- 
SELECT org_type FROM organism;
UPDATE
	organism
SET
	org_type = 'Prokaryote';
    
SELECT org_type FROM organism;
COMMIT;

ROLLBACK;



-----------------------------------------------------------------------------------------  
-- 8 Advanced Queries   
  
/* Query 13: Determine the count for literature published in 2020

   Business Purpose: This shows the most recent literature from the past year and displays 
   the date it was piblished, the journal name, the article title, scientific name of the    
   organism, the organism type and the count of references published in 2020. */
----------------------------------------------------------------------------------------- 
SELECT 
    rl.pub_date,  rl.journal, rl.article_title, o.scientific_name, o.org_type,

( SELECT COUNT(pub_date) FROM ref_literature 
	WHERE pub_date > date '2020-01-01') AS "Journals Published IN 2020"

FROM 
	ref_literature rl 
JOIN ORGANISM o ON rl.ref_id = o.ref_id
WHERE pub_date > date '2020-01-01';

-----------------------------------------------------------------------------------------        
/* Query 14: Display the molecular weights of proteins found in the Nsp1 region in  
   ascending order
  
   Business Purpose: This shows the FASTA ID, gene ID, protein ID, protein family and
   molecule weight of proteins found in the Nsp1 region from lightest to heaviest. Protein 
   molecular weight can be important when determining whether a property would be a good     
   therapuetic candiadate. */
----------------------------------------------------------------------------------------- 
SELECT  
    gm.fasta_id, g.gene_id, p.protein_id, p.pfam, P.mol_weight AS "Average Protein Weight in Nsp1 Region" 
FROM 
    protein p 
JOIN gene g ON g.gene_id = p.gene_id 
INNER JOIN genome gm ON gm.genome_id = g.genome_id
WHERE region_name = 'Nsp1' 
ORDER BY mol_weight ASC ;

-----------------------------------------------------------------------------------------   

/* Query 15: List the gene symbols and descriptions of those genes updated before 2020 

   Business Purpose: Shows the gene ID, gene symbol, gene description, FASTA ID for the    
   genome, the protein family and protein ID of the genes that have been updated before      
   2020. */
----------------------------------------------------------------------------------------- 
SELECT 
	g.last_update, g.gene_id, g.gene_symbol, g.gene_description, 
	gm.fasta_id, p.protein_id, p.pfam
FROM 
	gene g 
JOIN genome gm 	ON g.genome_id = gm.genome_id 
INNER JOIN protein p  ON g.gene_id = p.gene_id
WHERE g.last_update < date '2020-01-01';

-----------------------------------------------------------------------------------------    

/* Query 16: List the scientific name, DNA length, GC content, gene symbol and  protein
   family of the organisms with a protein coding gene type, where the DNA length is at least
   3000 and the GC content is no greater than 40%. Order by DNA length DESC/

  Business Purpose: This lists the organism's scientific name, the length of it's genome,
  the GC content, the gene symbol and protein family associated with the organism.   */
----------------------------------------------------------------------------------------- 
SELECT o.scientific_name, gm.dna_length,gm.gc_content, g.gene_symbol, p.pfam
FROM 
	organism o 
LEFT JOIN genome gm 
    ON gm.org_id = o.org_id 
JOIN  gene g 
	ON g.genome_id = gm.genome_id
JOIN protein p 
	ON p.gene_id = g.gene_id
WHERE g.gene_type = 'protein coding' 
    AND gm.dna_length > 3000
    AND gm.gc_content < 40
ORDER BY gm.dna_length DESC;

-----------------------------------------------------------------------------------------    

/* Query 17:  Display the scientific name along with the average GC content and those with 
   above average content.
   
   Business Purpose: High GC content has been correlated with the development of cancer in
   certain genes. We are listing organism's with an abnormally high GC content. */
----------------------------------------------------------------------------------------- 
 SELECT 
	o.scientific_name, gm.gc_content, a.avg_content
FROM 
	organism o 
JOIN genome gm ON gm.org_id = o.org_id , 
	(SELECT  AVG( gc_content) as avg_content FROM genome) a
WHERE gm.gc_content > a.avg_content;

-----------------------------------------------------------------------------------------      
/* Query 18:  List the gene that produces more than one protein.

   Business Purpose: This shows the scientific name of the organism, the gene symbol,
   protein ID, molecular weight of the proteins, and the protein family they belong to. */
----------------------------------------------------------------------------------------- 
SELECT 
 o.scientific_name, g.gene_symbol, p.protein_id, p.pfam, p.region_name, p.mol_weight
FROM 
	gene g 
JOIN protein p ON p.gene_id = g.gene_id
JOIN genome gm ON g.genome_id = gm.genome_id
JOIN organism o ON gm.org_id = o.org_id

WHERE g.gene_id = (SELECT G.GENE_ID
                    FROM gene g JOIN protein p   
                    ON p.gene_id = g.gene_id
                    GROUP BY g.gene_id
                    HAVING COUNT(*) >1);
                                   
-----------------------------------------------------------------------------------------     
/* Query 19: Find organisms and their proteins that share similar properties.

   Business Purpose: These proteins share the same protein families, gene symbols, and
   protein region names but they are from different genomes and not the same.  */
----------------------------------------------------------------------------------------- 
SELECT 
    g.genome_id, o.scientific_name, p.protein_id, p.mol_weight
FROM 
	gene g 
JOIN protein p ON p.gene_id = g.gene_id
JOIN genome gm ON g.genome_id = gm.genome_id
JOIN organism o ON gm.org_id = o.org_id

WHERE g.gene_symbol = (SELECT g.gene_symbol
                    FROM gene g JOIN protein p   
                    ON p.gene_id = g.gene_id
                    GROUP BY g.gene_symbol
                    HAVING COUNT(*) >1)
AND
p.region_name = (SELECT  p.region_name
                    FROM  protein p  
                    GROUP BY  p.region_name
                    HAVING COUNT(*) >1 )                                
AND
p.pfam = (SELECT  p.pfam
                    FROM  protein p  
                    GROUP BY  p.pfam
                    HAVING COUNT(*) >1 ) ;                    
                    
-----------------------------------------------------------------------------------------        
/* Query 20: List information from all five tables where the host is 'Homo sapien' and the      
   protein family is known but there are no repeated values. 

   Business Purpose: Shows the reference article title, scientific name of the organism, the    
   fasta ID, gene symbol associated with the genome and protein family of an organism found     
   in Homo sapiens and with a known protein family. */
----------------------------------------------------------------------------------------- 
SELECT DISTINCT
	rl.article_title, o.scientific_name, gm.fasta_id, g.gene_symbol, p.pfam

FROM
	ref_literature rl
JOIN organism o 
	ON rl.ref_id = o.ref_id
JOIN genome gm 
	ON gm.org_id = o.org_id
JOIN gene g 
	ON g.genome_id = gm.genome_id
JOIN protein p 
	ON p.gene_id = g.gene_id
WHERE o.host = 'Homo sapien'
AND p.pfam IS NOT NULL;

