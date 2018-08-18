PIXFOOD20_PATH := dataset/pixfood20/images
CATS := $(wildcard $(PIXFOOD20_PATH)/*)

CAT_PATH := $(PIXFOOD20_PATH)/$(CAT)
CAT_IMAGES_PATH := $(CAT_PATH)/食物
CAT_MASKED_PATH := $(CAT_PATH)/masked
CAT_CROPED_PATH := $(CAT_PATH)/croped

TEST_PATH := downloads/$(CAT)
TEST_MASKED_PATH := generative_inpainting/data/testset/$(CAT)/masked
TEST_CROPED_PATH := generative_inpainting/data/testset/$(CAT)/croped

cat_images := $(wildcard $(CAT_IMAGES_PATH)/*)
cat_croped := $(patsubst $(CAT_IMAGES_PATH)/%,$(CAT_CROPED_PATH)/%,$(cat_images))
cat_masked := $(patsubst $(CAT_IMAGES_PATH)/%,$(CAT_MASKED_PATH)/%,$(cat_images))
inpaint_yml := config/inpaint.$(CAT).yml

test_images := $(wildcard $(TEST_PATH)/*)
test_croped := $(patsubst $(TEST_PATH)/%,$(TEST_CROPED_PATH)/%,$(test_images))
test_masked := $(patsubst $(TEST_PATH)/%,$(TEST_MASKED_PATH)/%,$(test_images))

all: croped flist masked

masked: $(cat_masked)

croped: $(cat_croped)

generate-testset: download-dataset test-masked

download-dataset:
	googleimagesdownload -k "$(CAT)" -l 30 -f jpg 
	python rename_file.py $(CAT)

test-croped: $(test_croped)

test-masked: $(test_masked)

$(TEST_CROPED_PATH)/%: $(TEST_PATH)/%
	@mkdir -p `dirname $@`
	convert '$<'  -resize 256x256^ -gravity center -crop 256x256+0+0 '$@'

$(TEST_MASKED_PATH)/%: $(TEST_CROPED_PATH)/%
	@mkdir -p `dirname $@`
	convert '$<' -fill White -draw 'rectangle 64,64 192,128' '$@'

$(CAT_CROPED_PATH)/%: $(CAT_IMAGES_PATH)/%
	@mkdir -p `dirname $@`
	convert $<  -resize 256x256^ -gravity center -crop 256x256+0+0 $@

$(CAT_MASKED_PATH)/%: $(CAT_CROPED_PATH)/%
	@mkdir -p `dirname $@`
	convert $< -fill White -draw 'rectangle 64,64 192,128' $@

flist: croped
	mkdir -p 'generative_inpainting/data/pixfood20/${CAT}'
	python prepare_dataset.py \
		--folder_path `readlink -f '$(CAT_CROPED_PATH)'` \
		--train_filename 'generative_inpainting/data/pixfood20/${CAT}/train.flist' \
		--validation_filename 'generative_inpainting/data/pixfood20/${CAT}/valid.flist'

.ONESHELL:
inpaint-yml:
	cd generative_inpainting/
	mkdir -p config
	sed 's/<CAT>/$(CAT)/g' inpaint.yml.pixfood20.template > $(inpaint_yml)

.ONESHELL:
train:
	cd generative_inpainting/
	python train.py $(inpaint_yml)

debug:
	$(info CATS="$(CATS)")
	$(info CAT_IMAGES_PATH="$(CAT_IMAGES_PATH)")
	$(info cat_images="$(cat_images)")
	$(info cat_croped="$(cat_croped)")


